# encoding: utf-8

require 'readline'
require 'fileutils'
require 'yaml'
require 'thor'
require 'scribble/string'
require 'scribble/wheel'

class MyThor < Thor
  class << self
    protected
    def create_task(meth)
      @usage = meth
      @desc  = meth
      @hide  = false
      super
    end
  end
end

class Array
  def to_entry
    self.join(Scribble::Cli::DELIMITER)
  end
end

module Scribble
  class Cli < MyThor
    include Thor::Actions
    ENDLINE_MARK    = '---'
    DELIMITER       = ';'
    REPOSITORY_FILE = '.scribble'
    def self.source_root
      Dir.pwd
    end
    def initialize(args, opts, conf)
      load_settings
      @config = @settings.dup
      @config.merge!(conf)
      @option = @config[:option] || {}
      super(args, opts, conf)
    end
    # Create new task entry
    #
    # === Parameters
    # task<string>: task
    method_options :task => :string
    def add(task='')
      blackhole unless has_repository?
      tasks = read_file
      if tasks.length > 99
        puts "Too many tasks :("
        exit
      end
      task = task.dup
      date = Time.now
      insert_into_file(repository, thor_config) {
        begin
          while task = Readline.readline("New task <new task> or [exit,quit,q] ? ")
            exit if task =~ /^(exit|quit|q)$/
            break unless task.empty?
          end if task.empty?
          task.gsub!(/^['"]|['"]$/, '')
          valid_range = (@config[:min_width]..@config[:max_width])
          unless valid_range.include?(task.length)
            state = task.length > @config[:max_width] ? 'long' : 'short'
            while force = Readline.readline("Too #{state}, force add [Y,n] ? ")
              case force
              when /^[Yy]$/;  break
              when /^[Nn]$/, /^(exit|quit|q)$/; exit
              end
            end
          end
        rescue Interrupt # C-c
          system("stty", `stty -g`.chomp)
          puts
          exit
        end
        task_line = [task, 0, 0, date].to_entry
        task_line << "\n"
        task_line.force_encoding('ascii-8bit')
      }
      report("#{task} #{date}", 'created')
    end
    # Edit a task
    #
    # === Parameters
    # index<string>: index number
    method_options :index => :string
    def edit(index=nil)
      blackhole unless has_repository?
      task, done, mark, date = entry_of(index)
      exit unless task
      path = Tempfile.open('scribble') do |tf|
        tf.puts task
        tf.puts
        tf.puts <<-NOTE
# Please edit the task. First line #{@config[:max_width]} characters only,
# If task is empty, then it will be deleted.
#
# Current  : #{task}
# Created  : #{date}
# Tempfile : #{tf.path}
        NOTE
        tf.path
      end
      system("#{editor} #{path}")
      file = File.read(path)
      if new_task = file.split("\n").first
        if new_task.empty?
          delete(index)
        else
          gsub_task(task, new_task, 'updated')
        end
      end
    end
    # Delete a task
    #
    # === Parameters
    # index<string>: index number
    method_options :index => :string
    def delete(index=nil)
      blackhole unless has_repository?
      tasks = read_file
      exit unless task = tasks.delete(index)
      path = Tempfile.open('scribble') do |tf|
        tasks.keys.sort.each do |key|
          tf.puts tasks[key]
        end
        tf.puts settings_to_yaml
        tf.path
      end
      FileUtils.cp(path, repository)
      report(task, 'deleted')
    end
    # Create repository file
    def init
      if has_repository?
        puts "#{repository} already exists."
      else
        create_file(repository, thor_config){ |f| settings_to_yaml }
        puts "#{repository} is created."
      end
    end
    # Output list of tasks
    #
    # === Parameters
    # n<numeric>: numbers
    # r<boolean>: random output ?
    method_options :n => :numeric
    method_options :r => :boolean
    def list(n=nil, r=false, &block)
      blackhole unless has_repository?
      tasks = read_file
      return if tasks.empty?
      keys = tasks.keys.sort
      keys.shuffle! if random?
      keys = keys[0...number] if has_number?
      list = keys.map{ |key| { key => tasks[key] } }
      list_width = list.map do |task_hash|
        task_hash.values.first.width
      end.max - Time.now.to_s.width - 2 - (DELIMITER.width * 3)
      width = list_width < @config[:max_width] ? list_width : @config[:max_width]
      if has_number?
        puts "## \033[0;32m#{number}/#{tasks.length} tasks\033[0;37m"
      else
        puts "## \033[0;32m#{tasks.length} tasks\033[0;37m"
      end
      #puts "\033[0;36m@@ #{tasks.length} tasks @@\033[0;37m"
      list.each do |task_hash|
        index = task_hash.keys.first
        task, done, mark, date = entry_of(index)
        if task.width > width
          last = '...'
          task = task.rtrim(@config[:max_width] - last.width) + last
        end
        diff = width - task.width
        done = !done.to_i.zero?
        mark = !mark.to_i.zero?
        output(mark, index, task.rpad(diff), done, date)
        block.call(index, task) if block_given?
      end
    end
    # Say task(s)
    #
    # === Parameters
    # n<numeric>: numbers
    # r<boolean>: random output ?
    method_options :n => :numeric
    method_options :r => :boolean
    def say(n=nil, r=false)
      blackhole unless has_repository?
      case
      when !`which mplayer 2>/dev/null`.empty?; command = \
        'mplayer -really-quiet "http://translate.google.com/translate_tts?tl=en&q=number%s: %s"'
      when !`which espeak 2>/dev/null`.empty? && 
           !`which aplay 2>/dev/null`.empty?;   command = \
        'espeak --stdout "number%s: %s" 2>/dev/null | aplay >/dev/null 2>&1'
      when !`which say 2>/dev/null`.empty?;     command = \
        'say -v Alex "number%s: %s" >/dev/null 2>&1'
      else command = nil
      end
      unless command
        puts "mplayer, espeak or say command not found"
        list(n, r)
      else
        list(n, r) { |index, task|
          task = 'skipped' unless task.ascii_only?
          system(command % [index, task])
        }
      end
    end
    # done/undone, mark/unmark
    def self.define_update_method_for(name)
      define_method(name) { |index=nil|
        blackhole unless has_repository?
        task, done, mark, date = entry_of(index)
        if task
          old = [task, done, mark, date].to_entry
          case name
          when :done, :undone; done = (name == :done ? 1 : 0)
          when :mark, :unmark; mark = (name == :mark ? 1 : 0)
          end
          new = [task, done, mark, date].to_entry
          gsub_line(old, new, [:mark, :unmark].include?(name) ? "#{name}ed" : name)
        end
      }
    end
    %w(done undone mark unmark).each { |action|
      define_update_method_for(action.intern)
    }
    private
    def blackhole
      w = Wheel.new(0.03)
      20.times{ w.backward }
      puts "Please run `scribble init`"
      exit
    end
    def settings_to_yaml
      YAML.dump @settings
    end
    def load_settings
      @settings = {}
      if has_repository?
        File.open(repository) do |f|
          YAML.load_documents(f) do |y|
            @settings = y if y.is_a? Hash
          end
        end
      end
      @settings[:option]    ||= { number: nil, random: false }
      @settings[:max_width] ||= 51
      @settings[:min_width] ||= 3
    end
    def thor_config
      @thor_config ||= {
        before:      ENDLINE_MARK,
        force:       true,
        replacement: "",
        verbose:     false,
      }
    end
    def random?
      @option[:random] == true
    end
    def has_number?
      !@option[:number].to_i.zero?
    end
    def number
      @option[:number].to_i
    end
    def editor
      ENV['EDITOR'] || 'vim'
    end
    def repository
      @repository ||= File.join Scribble::Cli.source_root, REPOSITORY_FILE
    end
    def has_repository?
      File.exist?(repository)
    end
    def read_file
      return @_tasks if @_tasks
      @_tasks = {}
      i = 0
      w = Wheel.new(0.03) # relax :)
      File.open(repository) do |t|
        while line = t.gets.chomp
          w.forward
          break if line == ENDLINE_MARK
          next if line[0] == '#'
          head = i < 10 ? "0" + i.to_s : i.to_s
          @_tasks[head] = line.chomp
          i += 1
        end
      end
      @_tasks
    end
    def entry_of(index)
      entry = nil
      tasks = read_file
      if line = tasks[index]
        entry = line.split DELIMITER
      end
      entry
    end
    def gsub_task(task, new_task, state='updated')
      task.force_encoding('ascii-8bit')
      new_task.force_encoding('ascii-8bit')
      gsub_file(repository, task, thor_config) { |match|
        new_task
      }
      report(new_task, state)
    end
    alias :gsub_line :gsub_task
    def output(mark, index, task, done, created)
      puts "%s %s %s %s" % [
        done ? "\033[0;32m+\033[0;37m" : (mark ? "\033[0;31m-\033[0;37m" : ' '),
        "\033[1;30m[#{index}]\033[0;37m",
        done ? "\033[0;32m#{task}\033[0;37m" : (mark ? "\033[0;31m#{task}\033[0;37m" : "\033[0;37m#{task}\033[0;37m" ),
        "\033[1;30m#{created}\033[0;37m"
      ]
    end
    def report(task, state='')
      puts task.chomp.gsub(DELIMITER, ' ').force_encoding('utf-8') + " [#{state}]"
    end
  end
end

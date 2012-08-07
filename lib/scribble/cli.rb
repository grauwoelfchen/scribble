# encoding: utf-8

require 'readline'
require 'fileutils'
require 'yaml'
require 'thor'
require 'scribble/string'
require 'scribble/wheel'

module Scribble
  class Cli < Thor
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
    desc 'add', ''
    method_options :task => :string
    def add(task='')
      blackhole unless has_repository?
      task = task.dup
      insert_into_file(repository, thor_config) {
        begin
          while task = Readline.readline("New task <new task> or [exit,quit,q] ? ")
            exit if task =~ /^(exit|quit|q)$/
            break unless task.empty?
          end if task.empty?
          task.gsub!(/^['"]|['"]$/, '')
          valid_range = (@config[:min_width]...(@config[:max_width] + 1))
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
        task = [task, 0, 0, Time.now].join(DELIMITER)
        task << "\n"
        task.force_encoding('ascii-8bit')
      }
      report(task, "[created]")
    end
    desc 'edit', ''
    method_options :index => :string
    def edit(index=nil)
      blackhole unless has_repository?
      tasks = read_file
      exit unless line = tasks[index]
      entry = line.split DELIMITER
      task = entry.first
      date = entry.last
      path = Tempfile.open 'scribble' do |tf|
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
      file = File.read path
      if new_task = file.split("\n").first
        if new_task.empty?
          delete(index)
        else
          gsub_task(task, new_task, '[updated]')
        end
      end
    end
    desc 'delete', ''
    method_options :index => :string
    def delete(index=nil)
      blackhole unless has_repository?
      tasks = read_file
      exit unless task = tasks.delete(index)
      path = Tempfile.open 'scribble' do |tf|
        tasks.keys.sort.each do |key|
          tf.puts tasks[key]
        end
        tf.puts settings_to_yaml
        tf.path
      end
      FileUtils.cp path, repository
      report task, "[deleted]"
    end
    desc 'init', ''
    def init
      if has_repository?
        puts "#{repository} already exists."
      else
        create_file(repository, thor_config){ |f| settings_to_yaml }
        puts "#{repository} is created."
      end
    end
    desc 'list', ''
    method_options :n => :integer
    method_options :r => :boolean
    def list(n=nil, r=false)
      blackhole unless has_repository?
      tasks = read_file
      return if tasks.empty?
      keys = tasks.keys.sort
      keys.shuffle! if random?
      keys = keys[0...number]if has_number?
      list = keys.map{ |key| { key => tasks[key] } }
      list_width = list.map do |task_hash|
        task_hash.values.first.width
      end.max - Time.now.to_s.width - (2)- (DELIMITER.width * 3)
      width = list_width < @config[:max_width] ? list_width : @config[:max_width]
      puts "## \033[0;32m#{tasks.length} tasks\033[0;37m"
      #puts "\033[0;36m@@ #{tasks.length} tasks @@\033[0;37m"
      list.each do |task_hash|
        entry = task_hash.values.first.split DELIMITER
        task = entry[0]
        if task.width > width
          mark = '...'
          last = @config[:max_width] - mark.width
          task = task.rtrim(last) + mark
        end
        diff = width - task.width
        done = !entry[1].to_i.zero?
        mark = !entry[2].to_i.zero?
        date = entry[3]
        output(mark, task_hash.keys.first, task.rpad(diff), done, date)
      end
    end
    def self.define_completion_method(name)
      desc(name, '')
      define_method(name) { |index|
        blackhole unless has_repository?
        task, done, mark, date = entry_of(index)
        if task
          old = [task, done, mark, date].join(DELIMITER)
          new = [task, (name == :done ? 1 : 0), mark, date].join(DELIMITER)
          gsub_line(old, new, "[#{name}]")
        end
      }
    end
    define_completion_method :done
    define_completion_method :undone
    def self.define_marking_method(name)
      desc(name, '')
      define_method(name) { |index|
        blackhole unless has_repository?
        task, done, mark, date = entry_of(index)
        if task
          old = [task, done, mark, date].join(DELIMITER)
          new = [task, done, (name == :mark ? 1 : 0), date].join(DELIMITER)
          gsub_line(old, new, "[#{name}ed]")
        end
      }
    end
    define_marking_method :mark
    define_marking_method :unmark
    private
    def blackhole
      w = Wheel.new 0.03
      20.times do
        w.backward
      end
      puts "Please run `scribble init`"
      exit
    end
    def settings_to_yaml
      YAML.dump @settings
    end
    def load_settings
      @settings = {}
      if has_repository?
        File.open repository do |f|
          YAML.load_documents f do |y|
            @settings = y if y.is_a? Hash
          end
        end
      end
      @settings[:option] ||= { number: nil, random: false }
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
      File.exist? repository
    end
    def read_file
      tasks = {}
      i = 0
      w = Wheel.new 0.03 # relax :)
      File.open repository do |t|
        while line = t.gets.chomp
          w.forward
          break if line == ENDLINE_MARK
          next if line[0] == '#'
          head = i < 10 ? "0" + i.to_s : i.to_s
          tasks[head] = line.chomp
          i += 1
        end
      end
      tasks
    end
    def entry_of(index)
      entry = nil
      tasks = read_file
      if line = tasks[index]
        entry = line.split DELIMITER
      end
      entry
    end
    def gsub_task(task, new_task, state='[updated]')
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
      puts task.chomp.gsub(DELIMITER, ' ').force_encoding('utf-8') + " #{state}"
    end
  end
end

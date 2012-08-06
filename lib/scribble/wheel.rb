#!/usr/bin/env ruby
# encoding: utf-8

module Scribble
  class Wheel
    CR = "\r"
    WHEEL = ["\\", "|", "/", "-"]
    def initialize sec
      @sec = sec
      @index = 0
      STDOUT.sync = true
    end
    def self.define_spin name
      define_method name do
        wheel = (name =~ /back/ ? WHEEL.reverse : WHEEL)
        print wheel[(@index % 4)] + CR
        @index += 1
        sleep @sec
      end
    end
    define_spin :forward
    define_spin :backward
  end
end

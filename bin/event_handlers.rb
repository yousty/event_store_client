#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

class FooHandler
  def self.call(event)
    puts "Handled #{event.class.name} by FooHandler"
  end
end

class BarHandler
  def self.call(event)
    puts "Handled #{event.class.name} by BarHandler"
  end
end

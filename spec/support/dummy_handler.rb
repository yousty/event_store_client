# frozen_string_literal: true

class DummyHandler
  def self.call(event)
    puts "Handled #{event.class.name} by FooHandler"
  end
end

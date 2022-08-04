# frozen_string_literal: true

# This logger is used in tests unless ENV["DEBUG"] is set. It is important to return Object.new - it
# guards from false positive results when dev incidentally put `logger&.debug(something)` in the end
# of the method, but tests passed because there were no logger set, thus, making it to return `nil`.
# But, in this situation, if logger would be set - the returning result may be unexpected.
class DummyLogger
  class << self
    def info(*)
      Object.new
    end

    def debug(*)
      Object.new
    end

    def warn(*)
      Object.new
    end
  end
end

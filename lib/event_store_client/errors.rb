# frozen_string_literal: true

module EventStoreClient
  class Error < StandardError
    # @return [Hash]
    def as_json(*)
      to_h.transform_keys(&:to_s)
    end

    # @return [Hash]
    def to_h
      hash =
        instance_variables.each_with_object({}) do |var, result|
          key = var.to_s
          key[0] = '' # remove @ sign
          result[key.to_sym] = instance_variable_get(var)
        end
      hash[:message] = message
      hash[:backtrace] = backtrace
      hash
    end
  end

  class StreamNotFoundError < Error
    attr_reader :stream_name

    # @param stream_name [String]
    def initialize(stream_name)
      @stream_name = stream_name
      super("Stream #{stream_name.inspect} does not exist.")
    end
  end

  class WrongExpectedVersionError < Error
    attr_reader :wrong_expected_version, :caused_by

    # @param wrong_expected_version [EventStore::Client::Streams::AppendResp::WrongExpectedVersion]
    # @param caused_by [EventStoreClient::DeserializedEvent] an event on which
    #   WrongExpectedVersionError error happened. It can be useful when appending array of events -
    #   based on it you will know which events were appended and which weren't.
    def initialize(wrong_expected_version, caused_by:)
      @wrong_expected_version = wrong_expected_version
      @caused_by = caused_by
      super(user_friendly_message)
    end

    private

    # @return [String]
    def user_friendly_message
      if wrong_expected_version.expected_stream_exists
        return "Expected stream to exist, but it doesn't."
      end
      if wrong_expected_version.expected_no_stream
        return "Expected stream to be absent, but it actually exists."
      end
      if wrong_expected_version.current_no_stream
        return <<~TEXT.strip
          Stream revision #{wrong_expected_version.expected_revision.inspect} is expected, but \
          stream does not exist.
        TEXT
      end
      unless wrong_expected_version.expected_revision == wrong_expected_version.current_revision
        return <<~TEXT.strip
          Stream revision #{wrong_expected_version.expected_revision.inspect} is expected, but \
          actual stream revision is #{wrong_expected_version.current_revision.inspect}.
        TEXT
      end
      # Unhandled case. Could happen if something else would be added to proto and I don't add it
      # here.
      self.class.to_s
    end
  end

  class StreamDeletionError < Error
    attr_reader :stream_name, :details

    # @param stream_name [String]
    # @param details [String]
    def initialize(stream_name, details:)
      @stream_name = stream_name
      @details = details
      super(user_friendly_message)
    end

    # @return [String]
    def user_friendly_message
      <<~TEXT.strip
        Could not delete #{stream_name.inspect} stream. It seems that a stream with that \
        name does not exist, has already been deleted or its state does not match the \
        provided :expected_revision option. Please check #details for more info.
      TEXT
    end
  end
end

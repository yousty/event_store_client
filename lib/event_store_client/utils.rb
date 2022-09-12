# frozen_string_literal: true

module EventStoreClient
  class Utils
    class << self
      # @param uuid [EventStore::Client::UUID]
      # @return [String]
      def uuid_to_str(uuid)
        return uuid.string unless uuid.string.empty?

        msb =
          if uuid.structured.most_significant_bits.negative?
            (2**64) + uuid.structured.most_significant_bits
          else
            uuid.structured.most_significant_bits
          end
        lsb =
          if uuid.structured.least_significant_bits.negative?
            (2**64) + uuid.structured.least_significant_bits
          else
            uuid.structured.least_significant_bits
          end
        (msb.to_s(16) + lsb.to_s(16)).unpack('A8A4A4A4A12').join('-')
      end
    end
  end
end

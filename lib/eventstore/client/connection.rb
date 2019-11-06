# frozen_string_literal: true

module Eventstore
  module Client
    class Connection
      def initialize
        @host = "http://127.0.0.1"
        @port = 2113
        user_id = SecureRandom.uuid
        @url = "#{host}:#{port}/streams/newstream/head"
        # resp = Faraday.get(url, {a: 1}, {'Accept' => 'application/json'})
        # => GET http://sushi.com/nigiri/sake.json?a=1
        # application/vnd.eventstore.events+json
        # POST 'application/x-www-form-urlencoded' content

        # POST JSON content

        res = c.post do |req|
          req.body = {
            data: {
              user_id: user_id,
              email: 'jon@snow.com'
            },
            metadata: {
              created_at: Time.now
            }
          }.to_json
        end
        yield(self) if block_given?
      end

      private
    end
  end
end


# frozen_string_literal: true

module EventStoreClient
  module Connection
    class UrlParser
      class << self
        def boolean_param(value)
          return unless %w(true false).include?(value)

          value == 'true'
        end
      end

      ParsedUrl = Struct.new(:scheme, :host, :port, :user, :password, :params)
      # It is used to detect if string starts from some scheme. E.g. "esdb://", "esdb+discover://",
      # "http://", "https://" and so on
      SCHEME_REGEXP = /\A[\w|\+]*:\/\//.freeze

      # Define a set of rules to translate connection string into
      # EventStoreClient::Connection::Url options.
      #
      # "First url" means first extracted from the connection string url. It may contain schema,
      # discover flag, user name and password.
      # Example. Let's say a developer provided
      # "esdb+discover://admin:some-password@localhost:2112,localhost:2113" connection string. Then,
      # during parsing, the first url will be 'esdb+discover://admin:some-password@localhost:2112'
      FIRST_URL_RULES = {
        dns_discover: ->(parsed_url) { parsed_url.scheme&.include?('+discover') },
        username: ->(parsed_url) { parsed_url.user },
        password: ->(parsed_url) { parsed_url.password }
      }.freeze
      # "Last url" means the latest extracted url from the connections string. It contains params.
      # So LAST_URL_RULES rules defines rules how to translate params into
      # EventStoreClient::Connection::Url options.
      # Example. Let's say a developer provided
      # "esdb+discover://admin:some-password@localhost:2112,localhost:2113/?tls=false" connection
      # string. Then, during parsing, last url will be 'localhost:2113/?tls=false'.
      LAST_URL_RULES = {
        throw_on_append_failure: ->(parsed_url) {
          boolean_param(parsed_url.params['throwOnAppendFailure'])
        },
        tls: ->(parsed_url) { boolean_param(parsed_url.params['tls']) },
        tls_verify_cert: ->(parsed_url) { boolean_param(parsed_url.params['tlsVerifyCert']) },
        tls_ca_file: ->(parsed_url) { parsed_url.params['tlsCAFile'] },
        gossip_timeout: ->(parsed_url) { parsed_url.params['gossipTimeout']&.to_i },
        discover_interval: ->(parsed_url) { parsed_url.params['discoverInterval']&.to_i },
        max_discover_attempts: ->(parsed_url) { parsed_url.params['maxDiscoverAttempts']&.to_i },
        ca_lookup_interval: ->(parsed_url) { parsed_url.params['caLookupInterval']&.to_i },
        ca_lookup_attempts: ->(parsed_url) { parsed_url.params['caLookupAttempts']&.to_i },
        node_preference: ->(parsed_url) {
          value = parsed_url.params['nodePreference']&.dup
          if value
            value[0] = value[0]&.upcase
            value = value.to_sym
          end
          value if Url::NODE_PREFERENCES.include?(value)
        },
        connection_name: ->(parsed_url) { parsed_url.params['connectionName'] },
        timeout: ->(parsed_url) { parsed_url.params['timeout']&.to_i },
        grpc_retry_attempts: ->(parsed_url) { parsed_url.params['grpcRetryAttempts']&.to_i },
        grpc_retry_interval: ->(parsed_url) { parsed_url.params['grpcRetryInterval']&.to_i }
      }.freeze

      # @param connection_str [String] EventStore DB connection string
      # @return [EventStoreClient::Connection::Url]
      def call(connection_str)
        urls = connection_str.split(',')
        return Url.new if urls.empty?

        first_url, *other, last_url = urls

        es_url = Url.new
        if last_url.nil? # We are dealing with one node in the url
          options_from_first(es_url, first_url)
          options_from_last(es_url, first_url)
        else
          options_from_first(es_url, first_url)
          options_from_other(es_url, other)
          options_from_last(es_url, last_url)
        end

        es_url
      end

      private

      # @param es_url [EventStoreClient::Connection::Url]
      # @param first_url [String]
      # @return [void]
      def options_from_first(es_url, first_url)
        parsed_url = parse(first_url)
        return unless parsed_url

        FIRST_URL_RULES.each do |opt, rule|
          value = rule.call(parsed_url)
          es_url.public_send("#{opt}=", value) unless value.nil?
        end
        es_url.nodes.add(Url::Node.new(parsed_url.host, parsed_url.port))
      end

      # @param es_url [EventStoreClient::Connection::Url]
      # @param last_url [String, nil]
      # @return [void]
      def options_from_last(es_url, last_url)
        parsed_url = parse(last_url)
        return unless parsed_url

        LAST_URL_RULES.each do |opt, rule|
          value = rule.call(parsed_url)
          es_url.public_send("#{opt}=", value) unless value.nil?
        end
        es_url.nodes.add(Url::Node.new(parsed_url.host, parsed_url.port))
      end

      # @param es_url [EventStoreClient::Connection::Url]
      # @param urls [Array<String>]
      # @return [void]
      def options_from_other(es_url, urls)
        urls.each do |url|
          parsed_url = parse(url)
          next unless parsed_url

          es_url.nodes.add(Url::Node.new(parsed_url.host, parsed_url.port))
        end
      end

      # @param url [String, nil]
      # @return [EventStoreClient::Connection::UrlParser::ParsedUrl, nil]
      def parse(url)
        return unless url

        url = "esdb://#{url}" unless url.start_with?(SCHEME_REGEXP)
        uri = URI.parse(url)

        ParsedUrl.new(
          uri.scheme,
          uri.host,
          uri.port,
          uri.user,
          uri.password,
          URI.decode_www_form(uri.query.to_s).to_h
        )
      rescue URI::Error
      end
    end
  end
end

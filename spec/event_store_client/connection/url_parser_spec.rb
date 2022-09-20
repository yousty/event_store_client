# frozen_string_literal: true

RSpec.describe EventStoreClient::Connection::UrlParser do
  subject { instance }

  let(:instance) { described_class.new }

  describe 'constants' do
    describe 'ParsedUrl' do
      subject { described_class::ParsedUrl }

      it { is_expected.to be < Struct }

      describe 'instance' do
        subject { described_class::ParsedUrl.new(scheme, host, port, user, password, params) }

        let(:scheme) { 'esdb+discover' }
        let(:host) { 'localhost' }
        let(:port) { 2112 }
        let(:user) { 'admin' }
        let(:password) { 'some-password' }
        let(:params) { { 'foo' => 'bar' } }

        it 'has proper attributes' do
          aggregate_failures do
            expect(subject.scheme).to eq(scheme)
            expect(subject.host).to eq(host)
            expect(subject.port).to eq(port)
            expect(subject.user).to eq(user)
            expect(subject.password).to eq(password)
            expect(subject.params).to eq(params)
          end
        end
      end
    end

    describe 'SCHEME_REGEXP' do
      subject { described_class::SCHEME_REGEXP }

      let(:url) { 'esdb+discover://localhost:3001,localhost:3002/?foo=bar' }

      it 'matches a scheme from url' do
        expect(url.match(subject).to_s).to eq('esdb+discover://')
      end
    end

    describe 'FIRST_URL_RULES' do
      subject { described_class::FIRST_URL_RULES }

      let(:parsed_url) do
        described_class::ParsedUrl.new(scheme, host, port, user, password, nil)
      end
      let(:scheme) { 'esdb+discover' }
      let(:host) { 'localhost' }
      let(:port) { 2112 }
      let(:user) { 'admin' }
      let(:password) { 'some-password' }

      it { is_expected.to be_a(Hash) }
      it { is_expected.to be_frozen }
      it 'corresponds to the same Url options' do
        expect(EventStoreClient::Connection::Url.options.to_a).to include *subject.keys
      end

      describe 'rules' do
        describe ':dns_discover rule' do
          subject { super()[:dns_discover].call(parsed_url) }

          context 'when scheme is present' do
            context 'when scheme includes discover flag' do
              it { is_expected.to eq(true) }
            end

            context 'when scheme does not include discover flag' do
              let(:scheme) { 'esdb' }

              it { is_expected.to eq(false) }
            end
          end

          context 'when scheme is absent' do
            let(:scheme) { nil }

            it { is_expected.to be_nil }
          end
        end

        describe ':username rule' do
          subject { super()[:username].call(parsed_url) }

          it { is_expected.to eq(user) }
        end

        describe ':password rule' do
          subject { super()[:password].call(parsed_url) }

          it { is_expected.to eq(password) }
        end
      end
    end

    describe 'LAST_URL_RULES' do
      subject { described_class::LAST_URL_RULES }

      let(:parsed_url) do
        described_class::ParsedUrl.new(nil, nil, nil, nil, nil, params)
      end
      let(:params) { {} }

      it { is_expected.to be_a(Hash) }
      it { is_expected.to be_frozen }
      it 'corresponds to the same Url options' do
        expect(EventStoreClient::Connection::Url.options.to_a).to include *subject.keys
      end

      describe 'rules' do
        shared_examples 'boolean param' do
          context 'when value corresponds to "true" boolean value' do
            let(:params) { { param => 'true' } }

            it 'returns it' do
              is_expected.to eq(true)
            end
          end

          context 'when value corresponds to "false" boolean value' do
            let(:params) { { param => 'false' } }

            it 'returns it' do
              is_expected.to eq(false)
            end
          end

          context 'when value corresponds to something else' do
            let(:params) { { param => '1' } }

            it 'returns nil' do
              is_expected.to eq(nil)
            end
          end

          context 'when param is absent' do
            it { is_expected.to eq(nil) }
          end
        end

        shared_examples 'integer param' do
          context 'when value is present' do
            let(:params) { { param => '1' } }

            it { is_expected.to eq(params[param].to_i) }
          end

          context 'when param is absent' do
            it { is_expected.to eq(nil) }
          end
        end

        describe ':throw_on_append_failure rule' do
          subject { super()[:throw_on_append_failure].call(parsed_url) }

          it_behaves_like 'boolean param' do
            let(:param) { 'throwOnAppendFailure' }
          end
        end

        describe ':tls rule' do
          subject { super()[:tls].call(parsed_url) }

          it_behaves_like 'boolean param' do
            let(:param) { 'tls' }
          end
        end

        describe ':tls_verify_cert rule' do
          subject { super()[:tls_verify_cert].call(parsed_url) }

          it_behaves_like 'boolean param' do
            let(:param) { 'tlsVerifyCert' }
          end
        end

        describe ':tls_ca_file rule' do
          subject { super()[:tls_ca_file].call(parsed_url) }

          let(:params) { { 'tlsCAFile' => '/path/to/cert.crt' } }

          it { is_expected.to eq(params['tlsCAFile']) }
        end

        describe ':gossip_timeout rule' do
          subject { super()[:gossip_timeout].call(parsed_url) }

          it_behaves_like 'integer param' do
            let(:param) { 'gossipTimeout' }
          end
        end

        describe ':discover_interval rule' do
          subject { super()[:discover_interval].call(parsed_url) }

          it_behaves_like 'integer param' do
            let(:param) { 'discoverInterval' }
          end
        end

        describe ':max_discover_attempts rule' do
          subject { super()[:max_discover_attempts].call(parsed_url) }

          it_behaves_like 'integer param' do
            let(:param) { 'maxDiscoverAttempts' }
          end
        end

        describe ':ca_lookup_interval rule' do
          subject { super()[:ca_lookup_interval].call(parsed_url) }

          it_behaves_like 'integer param' do
            let(:param) { 'caLookupInterval' }
          end
        end

        describe ':ca_lookup_attempts rule' do
          subject { super()[:ca_lookup_attempts].call(parsed_url) }

          it_behaves_like 'integer param' do
            let(:param) { 'caLookupAttempts' }
          end
        end

        describe ':node_preference rule' do
          subject { super()[:node_preference].call(parsed_url) }

          context 'when nodePreference is present' do
            let(:params) { { 'nodePreference' => 'leader' } }

            context 'when value is "leader"' do
              it 'recognizes it' do
                is_expected.to eq(:Leader)
              end
            end

            context 'when value is "follower"' do
              let(:params) { { 'nodePreference' => 'follower' } }

              it 'recognizes it' do
                is_expected.to eq(:Follower)
              end
            end

            context 'when value is "readOnlyReplica"' do
              let(:params) { { 'nodePreference' => 'readOnlyReplica' } }

              it 'recognizes it' do
                is_expected.to eq(:ReadOnlyReplica)
              end
            end

            context 'when value is something else' do
              let(:params) { { 'nodePreference' => 'read' } }

              it { is_expected.to be_nil }
            end
          end

          context 'when nodePreference is absent' do
            it { is_expected.to be_nil }
          end
        end

        describe ':timeout rule' do
          subject { super()[:timeout].call(parsed_url) }

          it_behaves_like 'integer param' do
            let(:param) { 'timeout' }
          end
        end

        describe ':grpc_retry_attempts rule' do
          subject { super()[:grpc_retry_attempts].call(parsed_url) }

          it_behaves_like 'integer param' do
            let(:param) { 'grpcRetryAttempts' }
          end
        end

        describe ':grpc_retry_interval rule' do
          subject { super()[:grpc_retry_interval].call(parsed_url) }

          it_behaves_like 'integer param' do
            let(:param) { 'grpcRetryInterval' }
          end
        end
      end
    end
  end

  describe '#call' do
    subject { instance.call(connection_str) }

    let(:connection_str) { 'esdb://localhost:2111' }

    it { is_expected.to be_a(EventStoreClient::Connection::Url) }

    describe 'connection string features' do
      let(:url) { EventStoreClient::Connection::Url.new }
      let(:connection_str) do
        encoded_params = URI.encode_www_form(params)
        "esdb+discover://adm:passwd@localhost:2111,localhost:2112,localhost:2113/?#{encoded_params}"
      end
      let(:params) do
        {
          'throwOnAppendFailure' => false,
          'tls' => false,
          'tlsVerifyCert' => true,
          'tlsCAFile' => '/path/to/cert.crt',
          'gossipTimeout' => 100,
          'discoverInterval' => 202,
          'maxDiscoverAttempts' => 2,
          'caLookupInterval' => 200,
          'caLookupAttempts' => 4,
          'nodePreference' => 'follower',
          'connectionName' => 'some-name',
          'timeout' => 300,
          'grpcRetryAttempts' => 4,
          'grpcRetryInterval' => 400,
        }
      end

      before do
        allow(EventStoreClient::Connection::Url).to receive(:new).and_return(url)
      end

      it 'parses dns_discover correctly' do
        expect { subject }.to change { url.dns_discover }.to(true)
      end
      it 'parses username correctly' do
        expect { subject }.to change { url.username }.to('adm')
      end
      it 'parses password correctly' do
        expect { subject }.to change { url.password }.to('passwd')
      end
      it 'parses throw_on_append_failure correctly' do
        expect { subject }.to change {
          url.throw_on_append_failure
        }.to(params['throwOnAppendFailure'])
      end
      it 'parses tls correctly' do
        expect { subject }.to change { url.tls }.to(params['tls'])
      end
      it 'parses tls_verify_cert correctly' do
        expect { subject }.to change { url.tls_verify_cert }.to(params['tlsVerifyCert'])
      end
      it 'parses tls_ca_file correctly' do
        expect { subject }.to change { url.tls_ca_file }.to(params['tlsCAFile'])
      end
      it 'parses ca_lookup_interval correctly' do
        expect { subject }.to change { url.ca_lookup_interval }.to(params['caLookupInterval'])
      end
      it 'parses ca_lookup_attempts correctly' do
        expect { subject }.to change { url.ca_lookup_attempts }.to(params['caLookupAttempts'])
      end
      it 'parses gossip_timeout correctly' do
        expect { subject }.to change { url.gossip_timeout }.to(params['gossipTimeout'])
      end
      it 'parses discover_interval correctly' do
        expect { subject }.to change { url.discover_interval }.to(params['discoverInterval'])
      end
      it 'parses max_discover_attempts correctly' do
        expect { subject }.to change {
          url.max_discover_attempts
        }.to(params['maxDiscoverAttempts'])
      end
      it 'parses timeout correctly' do
        expect { subject }.to change { url.timeout }.to(params['timeout'])
      end
      it 'parses node_preference correctly' do
        expect { subject }.to change {
          url.node_preference
        }.to(params['nodePreference'].capitalize.to_sym)
      end
      it 'parses nodes correctly' do
        expect { subject }.to change {
          url.nodes
        }.to(
          Set.new(
            [
              EventStoreClient::Connection::Url::Node.new('localhost', 2111),
              EventStoreClient::Connection::Url::Node.new('localhost', 2112),
              EventStoreClient::Connection::Url::Node.new('localhost', 2113)
            ]
          )
        )
      end
      it 'parses grpc_retry_attempts correctly' do
        expect { subject }.to change {
          url.grpc_retry_attempts
        }.to(params['grpcRetryAttempts'])
      end
      it 'parses grpc_retry_interval correctly' do
        expect { subject }.to change {
          url.grpc_retry_interval
        }.to(params['grpcRetryInterval'])
      end
    end

    context 'when connection string is empty' do
      let(:connection_str) { '' }

      it { is_expected.to be_a(EventStoreClient::Connection::Url) }
      it 'returns Url with default options' do
        expect(subject.options_hash).to eq(EventStoreClient::Connection::Url.new.options_hash)
      end
    end
  end
end

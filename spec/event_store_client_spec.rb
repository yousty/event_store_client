# frozen_string_literal: true

RSpec.describe EventStoreClient do
  describe '.configure' do
    it 'yields config' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.config)
    end

    context 'when config name is provided' do
      let!(:config) { described_class.config(:some_config) }

      it 'yields correct config' do
        expect { |b| described_class.configure(name: :some_config, &b) }.to(
          yield_with_args(config)
        )
      end
    end
  end

  describe '.config' do
    subject { described_class.config }

    before do
      described_class.instance_variable_set(:@config, {})
    end

    it { is_expected.to be_a(described_class::Config) }
    it 'memorizes the config object' do
      expect(subject.__id__).to eq(described_class.config.__id__)
    end
    it 'persists the result under :default config' do
      expect { subject }.to change {
        described_class.instance_variable_get(:@config)
      }.to(hash_including(:default))
    end

    context 'when config name is provided' do
      subject { described_class.config(:some_config) }

      it { is_expected.to be_a(described_class::Config) }
      it 'memorizes the config object' do
        expect(subject.__id__).to eq(described_class.config(:some_config).__id__)
      end
      it 'persists the result under :some_config config' do
        expect { subject }.to change {
          described_class.instance_variable_get(:@config)
        }.to(hash_including(:some_config))
      end
    end
  end

  describe '.client' do
    subject { described_class.client }

    it { is_expected.to be_a(described_class::GRPC::Client) }
    it 'has default config' do
      expect(subject.send(:config)).to eq(described_class.config)
    end

    context 'when config name is given' do
      subject { described_class.client(config_name: config_name) }

      let(:config_name) { :some_config }

      context 'when config exists' do
        let!(:config) { described_class.config(config_name) }

        it 'uses that config' do
          expect(subject.send(:config)).to eq(config)
        end
      end

      context 'when config does not exist' do
        it 'raises error' do
          expect { subject }.to(
            raise_error(RuntimeError, /Could not find #{config_name.inspect} config/)
          )
        end
      end
    end
  end

  describe '.init_default_config' do
    subject { described_class.init_default_config }

    before do
      described_class.instance_variable_set(:@config, nil)
    end

    it 'assigns default config value' do
      expect { subject }.to change {
        described_class.instance_variable_get(:@config)
      }.from(nil).to(hash_including(default: instance_of(EventStoreClient::Config)))
    end
  end
end

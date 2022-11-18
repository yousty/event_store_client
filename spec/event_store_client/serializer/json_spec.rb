# frozen_string_literal: true

RSpec.describe EventStoreClient::Serializer::Json do
  describe '.deserialize' do
    subject { described_class.deserialize(data) }

    let(:data) { { foo: :bar } }

    context 'when data is a hash' do
      it 'returns it' do
        is_expected.to eq(data)
      end
    end

    context 'when data is a string' do
      let(:data) { { foo: :bar }.to_json }

      context 'when it is a correct JSOn string' do
        context 'when it is parsed into a hash' do
          it { is_expected.to eq('foo' => 'bar') }
        end

        context 'when it is parsed in something else' do
          let(:data) { [:foo, :bar].to_json }

          it 'wraps it into a hash' do
            is_expected.to eq('message' => ['foo', 'bar'])
          end
        end
      end

      context 'when it is an incorrect JSON' do
        let(:data) { 'foo' }

        it 'wraps it into a hash' do
          is_expected.to eq('message' => data)
        end
      end
    end

    context 'when data is something else' do
      let(:data) { Object.new }

      it 'raises error' do
        expect { subject }.to raise_error(TypeError)
      end
    end
  end

  describe '.serialize' do
    subject { described_class.serialize(data) }

    let(:data) { 'some data' }

    context 'when data is a string' do
      it 'returns it' do
        is_expected.to eq(data)
      end
    end

    context 'when data is something else' do
      let(:data) { { foo: :bar } }

      it 'serializes it' do
        is_expected.to eq(data.to_json)
      end
    end
  end
end

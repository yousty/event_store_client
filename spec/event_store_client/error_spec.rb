# frozen_string_literal: true

RSpec.describe EventStoreClient::Error do
  let(:instance) { described_class.new(message) }
  let(:message) { 'some message' }

  it { is_expected.to be_a(StandardError) }

  describe '#as_json' do
    subject { instance.as_json }

    it 'returns correct hash' do
      is_expected.to eq('message' => message, 'backtrace' => nil)
    end
  end

  describe '#to_h' do
    subject { instance.to_h }

    let(:foo) { 'foo-val' }

    before do
      instance.instance_variable_set(:@foo, foo)
    end

    it "computes a hash, based on error's details and error's variables" do
      is_expected.to eq(message: message, backtrace: nil, foo: foo)
    end
  end
end

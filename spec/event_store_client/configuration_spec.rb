# frozen_string_literal: true

RSpec.describe EventStoreClient::Configuration do
  let(:dummy_class) do
    Class.new.tap do |c|
      c.include described_class
    end
  end
  let(:dummy_instance) { dummy_class.new }

  describe '#config' do
    subject { dummy_instance.config }

    it 'returns config instance' do
      is_expected.to eq(EventStoreClient.config)
    end
  end
end

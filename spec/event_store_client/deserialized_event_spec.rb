# frozen_string_literal: true

RSpec.describe EventStoreClient::DeserializedEvent do
  let(:instance) do
    described_class.new(
      data: { 
        'user_id' => '7b5eb54c-122a-45e9-8d76-d15dfc2d8ece', 'title' => 'Something happened' 
      },
      type: 'some-event', 
      metadata: {
        'type' => 'some-event', 'created_at' => '2022-07-13 16:31:37 +0300',
        'content-type' => 'application/json', 'created' => '16577190979005637'
      },
      stream_name: 'some-stream',
      stream_revision: 195,
      prepare_position: 270566,
      commit_position: 270566,
      title: '195@some-stream',
      id: '6a71275a-afc3-4493-9797-57d19bd812d0'
    )
  end

  describe 'constants' do
    describe 'LINK_TYPE' do
      subject { described_class::LINK_TYPE }

      it { is_expected.to eq('$>') }
      it { is_expected.to be_frozen }
    end
  end

  describe '#==' do
    subject { instance == another_event }

    let(:another_event) { Object.new }

    context 'when comparing with incompatible object' do
      it { is_expected.to eq(false) }
    end

    context 'when comparing with EventStoreClient::DeserializedEvent' do
      let(:another_event) { described_class.new(id: instance.id) }

      context 'when some of attributes mismatch' do
        it { is_expected.to eq(false) }
      end

      context 'when all attributes matches' do
        let(:another_event) { described_class.new(instance.to_h) }

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#to_h' do
    subject { instance.to_h }

    it { is_expected.to be_a(Hash) }
    it 'returns hash representation of its attributes' do
      aggregate_failures do
        expect(subject[:id]).to eq(instance.id)
        expect(subject[:data]).to eq(instance.data)
        expect(subject[:type]).to eq(instance.type)
        expect(subject[:title]).to eq(instance.title)
        expect(subject[:metadata]).to eq(instance.metadata)
        expect(subject[:stream_name]).to eq(instance.stream_name)
        expect(subject[:stream_revision]).to eq(instance.stream_revision)
        expect(subject[:prepare_position]).to eq(instance.prepare_position)
        expect(subject[:commit_position]).to eq(instance.commit_position)
      end
    end
  end

  describe '#link?' do
    subject { instance.link? }

    context 'when event is a regular event' do
      it { is_expected.to eq(false) }
    end

    context 'when event is a link event' do
      let(:instance) { described_class.new(type: '$>') }

      it { is_expected.to eq(true) }
    end
  end
end

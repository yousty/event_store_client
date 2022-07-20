# frozen_string_literal: true

RSpec.describe EventStoreClient::DeserializedEvent do
  let(:deserialized_event) do
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

  describe '#==' do
    subject { deserialized_event == another_event }

    let(:another_event) { Object.new }

    context 'when comparing with incompatible object' do
      it { is_expected.to eq(false) }
    end

    context 'when comparing with EventStoreClient::DeserializedEvent' do
      let(:another_event) { described_class.new(id: deserialized_event.id) }

      context 'when some of attributes mismatch' do
        it { is_expected.to eq(false) }
      end

      context 'when all attributes matches' do
        let(:another_event) { described_class.new(deserialized_event.to_h) }

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#to_h' do
    subject { deserialized_event.to_h }

    it { is_expected.to be_a(Hash) }
    it 'returns hash representation of its attributes' do
      aggregate_failures do
        expect(subject[:id]).to eq(deserialized_event.id)
        expect(subject[:data]).to eq(deserialized_event.data)
        expect(subject[:type]).to eq(deserialized_event.type)
        expect(subject[:title]).to eq(deserialized_event.title)
        expect(subject[:metadata]).to eq(deserialized_event.metadata)
        expect(subject[:stream_name]).to eq(deserialized_event.stream_name)
        expect(subject[:stream_revision]).to eq(deserialized_event.stream_revision)
        expect(subject[:prepare_position]).to eq(deserialized_event.prepare_position)
        expect(subject[:commit_position]).to eq(deserialized_event.commit_position)
      end
    end
  end
end

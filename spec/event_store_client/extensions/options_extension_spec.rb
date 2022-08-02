# frozen_string_literal: true

RSpec.describe EventStoreClient::Extensions::OptionsExtension do
  let(:dummy_class) do
    klass = Class.new
    klass.include described_class
    klass
  end
  let(:instance) { dummy_class.allocate }

  describe 'defining option' do
    subject { dummy_class.option(option) }

    let(:option) { :some_opt }

    it 'defines reader' do
      subject
      expect(instance).to respond_to(option)
    end
    it 'defines writer' do
      subject
      expect(instance).to respond_to("#{option}=")
    end
    it 'adds that option to the options list' do
      expect { subject }.to change { dummy_class.options }.to(Set.new([option]))
    end

    context 'when block is provided' do
      subject { dummy_class.option(option, &blk) }

      let(:blk) { proc { 'some-value' } }

      it 'defines default value of option' do
        subject
        expect(instance.public_send(option)).to eq(blk.call)
      end
    end
  end

  describe 'defining options in inherited class' do
    let(:child) { Class.new(dummy_class) }
    let(:child_of_child) { Class.new(child) }

    before do
      dummy_class.option(:parent_opt)
      child.option(:child_opt)
      child_of_child.option(:child_of_child_opt)
    end

    it 'inherits all options from parent to the child correctly' do
      expect(child.options).to eq(Set.new([:parent_opt, :child_opt]))
    end
    it 'inherits all options from parent to the child of child correctly' do
      expect(child_of_child.options).to(
        eq(Set.new([:parent_opt, :child_opt, :child_of_child_opt]))
      )
    end
    it 'freezes options sets of children' do
      aggregate_failures do
        expect(child.options).to be_frozen
        expect(child_of_child.options).to be_frozen
      end
    end
  end

  describe '.options' do
    subject { dummy_class.options }

    it { is_expected.to be_a(Set) }
    it { is_expected.to be_frozen }
  end

  describe '#options_hash' do
    subject { instance.options_hash }

    before do
      dummy_class.option(:opt_1) { 'opt-1-value' }
      dummy_class.option(:opt_2) { 'opt-2-value' }
    end

    it 'returns hash representation of options' do
      is_expected.to eq(opt_1: 'opt-1-value', opt_2: 'opt-2-value')
    end
  end

  describe 'reader' do
    subject { instance.public_send(option) }

    let(:option) { :some_option }

    before do
      dummy_class.option(option)
    end

    context 'when default value is not set' do
      it { is_expected.to be_nil }
    end

    context 'when default value is set' do
      let(:blk) { proc { 'some-value' } }

      before do
        dummy_class.option(option, &blk)
      end

      it 'returns it' do
        is_expected.to eq(blk.call)
      end

      describe 'context of default value' do
        let(:blk) { proc { some_instance_method } }

        before do
          dummy_class.define_method(:some_instance_method) { 'some-instance-method-value' }
        end

        it 'processes it correctly' do
          is_expected.to eq('some-instance-method-value')
        end
      end
    end
  end
end

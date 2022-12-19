# frozen_string_literal: true

# This matcher is defined to test options which are defined by using
# EventStoreClient::Extensions::OptionsExtension option. Example:
# Let's say you have next class
# class SomeClass
#   include EventStoreClient::Extensions::OptionsExtension
#
#   option(:some_opt) { '1' }
# end
#
# To test that its instance has the proper option with the proper default value you can use this
# matcher:
# RSpec.describe SomeClass do
#   subject { described_class.new }
#
#   # Check that :some_opt is present
#   it { is_expected.to have_option(:some_opt) }
#   # Check that :some_opt is present and has the correct default value
#   it { is_expected.to have_option(:some_opt).with_default_value('1') }
# end
#
# If you have more complex implementation of default value of your option - you should handle it
# customly. For example:
# class SomeClass
#   include EventStoreClient::Extensions::OptionsExtension
#
#   option(:some_opt) { calc_value }
# end
# You could test it like so:
# RSpec.described SomeClass do
#   let(:instance) { described_class.new }
#
#   describe ':some_opt default value' do
#     subject { instance.some_opt }
#
#     let(:value) { 'some val' }
#
#     before do
#       allow(instance).to receive(:calc_value).and_return(value)
#     end
#
#     it { is_expected.to eq(value) }
#   end
# end
RSpec::Matchers.define :has_option do |option_name|
  match do |obj|
    option_presence = obj.class.respond_to?(:options) && obj.class.options.include?(option_name)
    if @default_value
      option_presence && obj.class.allocate.public_send(option_name) == @default_value
    else
      option_presence
    end
  end

  failure_message do |obj|
    option_presence = obj.class.respond_to?(:options) && obj.class.options.include?(option_name)
    if option_presence && @default_value
      msg = "Expected #{obj.class} to have `#{option_name.inspect}' option with #{@default_value.inspect}"
      msg += ' default value, but default value is'
      msg += " #{obj.class.allocate.public_send(option_name).inspect}"
    else
      msg = "Expected #{obj} to have `#{option_name.inspect}' option."
    end

    msg
  end

  description do
    expected_list = RSpec::Matchers::EnglishPhrasing.list(expected)
    sentences =
      @chained_method_clauses.map do |(method_name, method_args)|
        next '' if method_name == :required_kwargs

        english_name = RSpec::Matchers::EnglishPhrasing.split_words(method_name)
        arg_list = RSpec::Matchers::EnglishPhrasing.list(method_args)
        " #{english_name}#{arg_list}"
      end.join

    "have#{expected_list} option#{sentences}"
  end

  chain :with_default_value do |val|
    @default_value = val
  end
end

RSpec::Matchers.alias_matcher :have_option, :has_option

# frozen_string_literal: true

RSpec::Matchers.define :has_option do |option_name|
  @required_args = { args: [], kwargs: {}, block: nil }

  def fresh_instance(obj)
    obj.class.new(*@required_args[:args], **@required_args[:kwargs], &@required_args[:block])
  end

  match do |obj|
    option_presence = obj.class.respond_to?(:options) && obj.class.options.include?(option_name)
    if @default_value
      option_presence && fresh_instance(obj).public_send(option_name) == @default_value
    else
      option_presence
    end
  end

  failure_message do |obj|
    option_presence = obj.class.respond_to?(:options) && obj.class.options.include?(option_name)
    if option_presence && @default_value
      msg = "Expected #{obj.class} to have `#{option_name.inspect}' option with #{@default_value.inspect}"
      msg += ' default value, but default value is'
      msg += " #{fresh_instance(obj).public_send(option_name).inspect}"
    else
      msg = "Expected #{obj} to have `#{option_name.inspect}' option."
    end

    msg
  end

  description do
    expected_list = RSpec::Matchers::EnglishPhrasing.list(expected)
    sentences =
      @chained_method_clauses.map do |(method_name, method_args)|
        next '' if method_name == :required_args

        english_name = RSpec::Matchers::EnglishPhrasing.split_words(method_name)
        arg_list = RSpec::Matchers::EnglishPhrasing.list(method_args)
        " #{english_name}#{arg_list}"
      end.join

    "have#{expected_list} option#{sentences}"
  end

  chain :with_default_value do |val|
    @default_value = val
  end

  chain :required_args do |*args, **kwargs, &blk|
    @required_args = { args: args, kwargs: kwargs, block: blk }
  end
end

RSpec::Matchers.alias_matcher :have_option, :has_option

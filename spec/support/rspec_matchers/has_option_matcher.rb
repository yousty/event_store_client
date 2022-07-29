# frozen_string_literal: true

RSpec::Matchers.define :has_option do |option_name|
  match do |obj|
    option_presence = obj.class.respond_to?(:options) && obj.class.options.include?(option_name)
    if @default_value
      option_presence && obj.class.new.public_send(option_name) == @default_value
    else
      option_presence
    end
  end

  failure_message do |obj|
    option_presence = obj.class.respond_to?(:options) && obj.class.options.include?(option_name)
    if option_presence && @default_value
      msg = "Expected #{obj.class} to have `#{option_name.inspect}' option with #{@default_value.inspect}"
      msg += ' default value, but default value is'
      msg += " #{obj.class.new.public_send(option_name).inspect}"
    else
      msg = "Expected #{obj} to have `#{option_name.inspect}' option."
    end

    msg
  end

  chain :with_default_value do |val|
    @default_value = val
  end
end

RSpec::Matchers.alias_matcher :have_option, :has_option

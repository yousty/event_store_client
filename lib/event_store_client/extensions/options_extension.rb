# frozen_string_literal: true

module EventStoreClient
  module Extensions
    # A very simple extension that implements a DLS for adding attr_accessors with default values,
    # and assigning their values during object initialization.
    # Example. Let's say you frequently do something like this:
    # ```ruby
    # class SomeClass
    #   attr_accessor :attr1, :attr2, :attr3, :attr4
    #
    #   def initialize(opts = {})
    #     @attr1 = opts[:attr1] || 'Attr 1 value'
    #     @attr2 = opts[:attr2] || 'Attr 2 value'
    #     @attr3 = opts[:attr3] || do_some_calc
    #     @attr4 = opts[:attr4]
    #   end
    #
    #   def do_some_calc
    #   end
    # end
    #
    # SomeClass.new(attr1: 'hihi', attr4: 'byebye')
    # ```
    #
    # You can replace the code above using the OptionsExtension:
    # ```ruby
    # class SomeClass
    #   include EventStoreClient::Extensions::OptionsExtension
    #
    #   option(:attr1) { 'Attr 1 value' }
    #   option(:attr2) { 'Attr 2 value' }
    #   option(:attr3) { do_some_calc }
    #   option(:attr4)
    # end
    #
    # SomeClass.new(attr1: 'hihi', attr4: 'byebye')
    # ```
    module OptionsExtension
      module ClassMethods
        # @param opt_name [Symbol] option name
        # @param blk [Proc] provide define value using block. It will be later evaluated in the
        #   context of your object to determine the default value of the option
        # @return [Symbol]
        def option(opt_name, &blk)
          self.options = (options + Set.new([opt_name])).freeze
          attr_writer opt_name

          define_method opt_name do
            result = instance_variable_get(:"@#{opt_name}")
            return result if instance_variable_defined?(:"@#{opt_name}")

            instance_exec(&blk) if blk
          end
        end

        def inherited(klass)
          super
          klass.options = Set.new(options).freeze
        end
      end

      def self.included(klass)
        klass.singleton_class.attr_accessor(:options)
        klass.options = Set.new.freeze
        klass.extend(ClassMethods)
      end

      def initialize(**options)
        self.class.options.each do |option|
          # init default values of options
          value = options.key?(option) ? options[option] : public_send(option)
          public_send("#{option}=", value)
        end
      end

      # Construct a hash from options, where key is the option's name and the value is option's
      # value
      # @return [Hash]
      def options_hash
        self.class.options.each_with_object({}) do |option, res|
          res[option] = public_send(option)
        end
      end
    end
  end
end

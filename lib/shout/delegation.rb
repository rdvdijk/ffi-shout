# frozen_string_literal: true

module Shout
  # Class macros that define attribute readers and writers delegating to
  # libshout's shout_get_<name> / shout_set_<name> functions.
  module Delegation
    # Defines <name> and <name>= for each name. With predicate: true, also
    # defines <name>? returning a boolean (for on/off flags such as :public).
    def delegate_to_shout(*delegations, predicate: false)
      delegations.each do |name|
        define_setter_delegator(name, name)
        define_getter_delegator(name, name)
        define_predicate_delegator(name) if predicate
      end
    end

    def delegate_alias_to_shout(delegations)
      delegations.each_pair do |from, to|
        define_setter_delegator(from, to)
        define_getter_delegator(from, to)
      end
    end

    private

    def define_setter_delegator(from, to, preset = "shout")
      define_method(:"#{from}=") do |value|
        converted_value = TypeConvertor.convert(value)
        ret = Native.public_send(:"#{preset}_set_#{to}", shout, converted_value)
        Error.check_error(ret, shout)
        value
      end
    end

    def define_getter_delegator(from, to, preset = "shout")
      define_method(:"#{from}") do
        Native.public_send(:"#{preset}_get_#{to}", shout)
      end
    end

    def define_predicate_delegator(name)
      define_method(:"#{name}?") do
        TypeConvertor.convert_return(public_send(name))
      end
    end

    # Converts Ruby values to what libshout's setters expect. Booleans become
    # 1 / 0; symbols for formats, protocols, TLS and blocking modes are
    # converted by the FFI enums in Shout::Native, which also make the
    # matching readers return symbols such as :mp3.
    class TypeConvertor
      # Symbols that libshout treats as another name for the same value.
      ALIASES = { vorbis: :ogg }.freeze

      def self.convert(value)
        case value
        when true then 1
        when false then 0
        else ALIASES.fetch(value, value)
        end
      end

      def self.convert_return(value)
        case value
        when 0, false, nil
          false
        else
          true
        end
      end
    end
  end
end

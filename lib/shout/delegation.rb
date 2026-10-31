# frozen_string_literal: true

module Shout
  # Class macros that define attribute readers and writers delegating to
  # libshout's shout_get_<name> / shout_set_<name> functions.
  module Delegation
    def delegate_to_shout(*delegations)
      delegations.each do |flag|
        define_setter_delegator(flag, flag)
        define_getter_delegator(flag, flag)
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
        ret = ::Shout.public_send(:"#{preset}_set_#{to}", shout, converted_value)
        Error.check_error(ret, shout)
        value
      end
    end

    def define_getter_delegator(from, to, preset = "shout")
      define_method(:"#{from}") do
        ::Shout.public_send(:"#{preset}_get_#{to}", shout)
      end
      define_method(:"#{from}?") do
        return_value = public_send(:"#{from}")
        TypeConvertor.convert_return(return_value)
      end
    end

    # Converts Ruby values (booleans, symbols such as :mp3 or :http) to the
    # integers libshout expects, and libshout return values back to booleans.
    class TypeConvertor
      PROTOCOLS = {
        http: ::Shout::SHOUT_PROTOCOL_HTTP,
        xaudiocast: ::Shout::SHOUT_PROTOCOL_XAUDIOCAST,
        icy: ::Shout::SHOUT_PROTOCOL_ICY,
        roaraudio: ::Shout::SHOUT_PROTOCOL_ROARAUDIO
      }.freeze

      FORMATS = {
        ogg: ::Shout::SHOUT_FORMAT_OGG,
        mp3: ::Shout::SHOUT_FORMAT_MP3,
        webm: ::Shout::SHOUT_FORMAT_WEBM,
        webmaudio: ::Shout::SHOUT_FORMAT_WEBMAUDIO,
        matroska: ::Shout::SHOUT_FORMAT_MATROSKA,
        text: ::Shout::SHOUT_FORMAT_TEXT,
        vorbis: ::Shout::SHOUT_FORMAT_VORBIS
      }.freeze

      TLS_MODES = {
        disabled: ::Shout::SHOUT_TLS_DISABLED,
        auto: ::Shout::SHOUT_TLS_AUTO,
        auto_no_plain: ::Shout::SHOUT_TLS_AUTO_NO_PLAIN,
        rfc2818: ::Shout::SHOUT_TLS_RFC2818,
        rfc2817: ::Shout::SHOUT_TLS_RFC2817
      }.freeze

      BLOCKING_MODES = {
        full: ::Shout::SHOUT_BLOCKING_FULL,
        none: ::Shout::SHOUT_BLOCKING_NONE,
        default: ::Shout::SHOUT_BLOCKING_DEFAULT
      }.freeze

      # All symbol names above, mapped to their libshout constant.
      SYMBOLS = PROTOCOLS.merge(FORMATS, TLS_MODES, BLOCKING_MODES).freeze

      def self.convert(value)
        case value
        when true then 1
        when false then 0
        when Symbol then SYMBOLS.fetch(value, value)
        else value
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

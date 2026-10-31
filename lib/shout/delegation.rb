module Shout
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
        ret = ::Shout.send(:"#{preset}_set_#{to}", shout, converted_value)
        Error.check_error(ret, shout) if ret.is_a?(Integer) && ret < 0
        value
      end
    end

    def define_getter_delegator(from, to, preset = "shout")
      define_method(:"#{from}") do
        ::Shout.send(:"#{preset}_get_#{to}", shout)
      end
      define_method(:"#{from}?") do
        return_value = send(:"#{from}")
        TypeConvertor.convert_return(return_value)
      end
    end

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

      def self.convert(value)
        case value
        when true
          1
        when false
          0
        when Symbol
          if PROTOCOLS.key?(value)
            PROTOCOLS[value]
          elsif FORMATS.key?(value)
            FORMATS[value]
          elsif TLS_MODES.key?(value)
            TLS_MODES[value]
          elsif BLOCKING_MODES.key?(value)
            BLOCKING_MODES[value]
          else
            value
          end
        else
          value
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

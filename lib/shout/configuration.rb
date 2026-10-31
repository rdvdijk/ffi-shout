# frozen_string_literal: true

module Shout
  # Base class for configuration objects that read and write settings on a
  # libshout handle.
  class ConfigurationBase
    extend Delegation

    attr_reader :shout

    def initialize(shout)
      @shout = shout
    end
  end

  # Connection settings (host, mount, credentials, protocol, ...) stored on a
  # libshout handle. Each attribute reads and writes the matching
  # shout_get_*/shout_set_* function.
  class Configuration < ConfigurationBase
    delegate_alias_to_shout username: :user,
                            pass: :password,
                            mountpoint: :mount,
                            user_agent: :agent

    delegate_to_shout :host, :port, :agent, :tls, :ca_directory, :ca_file,
                      :allowed_ciphers, :user, :password, :client_certificate,
                      :mount, :public, :content_language, :protocol, :nonblocking

    # Obsolete methods supported by libshout for backwards compatibility
    delegate_to_shout :name, :url, :genre, :description, :format, :dumpfile

    def audio_info
      @audio_info ||= AudioInfo.new(shout)
    end

    def meta
      @meta ||= Meta.new(shout)
    end

    def content_format
      @content_format ||= ContentFormat.new(shout)
    end

    def set_content_format(format, usage = SHOUT_USAGE_AUDIO, codecs = nil)
      content_format.set(format, usage, codecs)
    end

    # Audio parameters advertised to the server (shout_set_audio_info).
    class AudioInfo < ConfigurationBase
      def bitrate=(value)
        set(SHOUT_AI_BITRATE, value)
      end

      def bitrate
        get(SHOUT_AI_BITRATE)
      end

      def samplerate=(value)
        set(SHOUT_AI_SAMPLERATE, value)
      end

      def samplerate
        get(SHOUT_AI_SAMPLERATE)
      end

      def channels=(value)
        set(SHOUT_AI_CHANNELS, value)
      end

      def channels
        get(SHOUT_AI_CHANNELS)
      end

      def quality=(value)
        set(SHOUT_AI_QUALITY, value)
      end

      def quality
        get(SHOUT_AI_QUALITY)
      end

      def [](key)
        get(key)
      end

      def []=(key, value)
        set(key, value)
      end

      private

      def set(key, value)
        str_val = value&.to_s
        ret = ::Shout.shout_set_audio_info(shout, key.to_s, str_val)
        Error.check_error(ret, shout)
        value
      end

      def get(key)
        ::Shout.shout_get_audio_info(shout, key.to_s)
      end
    end

    # Stream description such as name, genre and URL (shout_set_meta).
    class Meta < ConfigurationBase
      def name=(value)
        set(SHOUT_META_NAME, value)
      end

      def name
        get(SHOUT_META_NAME)
      end

      def url=(value)
        set(SHOUT_META_URL, value)
      end

      def url
        get(SHOUT_META_URL)
      end

      def genre=(value)
        set(SHOUT_META_GENRE, value)
      end

      def genre
        get(SHOUT_META_GENRE)
      end

      def description=(value)
        set(SHOUT_META_DESCRIPTION, value)
      end

      def description
        get(SHOUT_META_DESCRIPTION)
      end

      def irc=(value)
        set(SHOUT_META_IRC, value)
      end

      def irc
        get(SHOUT_META_IRC)
      end

      def aim=(value)
        set(SHOUT_META_AIM, value)
      end

      def aim
        get(SHOUT_META_AIM)
      end

      def icq=(value)
        set(SHOUT_META_ICQ, value)
      end

      def icq
        get(SHOUT_META_ICQ)
      end

      def [](key)
        get(key)
      end

      def []=(key, value)
        set(key, value)
      end

      private

      def set(key, value)
        str_val = value&.to_s
        ret = ::Shout.shout_set_meta(shout, key.to_s, str_val)
        Error.check_error(ret, shout)
        value
      end

      def get(key)
        ::Shout.shout_get_meta(shout, key.to_s)
      end
    end

    # Content format, usage and codecs of the stream (shout_set_content_format).
    class ContentFormat < ConfigurationBase
      def set(format, usage = SHOUT_USAGE_AUDIO, codecs = nil)
        fmt = Delegation::TypeConvertor.convert(format)
        ret = ::Shout.shout_set_content_format(shout, fmt, usage, codecs)
        Error.check_error(ret, shout)
        ret
      end

      def format
        info[0]
      end

      def usage
        info[1]
      end

      def codecs
        info[2]
      end

      private

      def info
        format_ptr = ::FFI::MemoryPointer.new(:uint)
        usage_ptr  = ::FFI::MemoryPointer.new(:uint)
        codecs_ptr = ::FFI::MemoryPointer.new(:pointer)

        ret = ::Shout.shout_get_content_format(shout, format_ptr, usage_ptr, codecs_ptr)
        Error.check_error(ret, shout)

        c_str_ptr = codecs_ptr.read_pointer
        codecs_str = c_str_ptr.null? ? nil : c_str_ptr.read_string

        [format_ptr.read_uint, usage_ptr.read_uint, codecs_str]
      end
    end
  end
end

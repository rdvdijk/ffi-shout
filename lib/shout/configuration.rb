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
                      :mount, :content_language, :protocol, :nonblocking

    delegate_to_shout :public, predicate: true

    # Settings that libshout marks obsolete. Their writers print a deprecation
    # warning (shown with `ruby -W:deprecated`).
    OBSOLETE_SETTINGS = {
      name: "meta.name=",
      url: "meta.url=",
      genre: "meta.genre=",
      description: "meta.description=",
      format: "set_content_format",
      dumpfile: nil # only useful with the deprecated xaudiocast protocol
    }.freeze

    delegate_to_shout(*OBSOLETE_SETTINGS.keys)

    prepend(Module.new do
      OBSOLETE_SETTINGS.each do |name, replacement|
        define_method(:"#{name}=") do |value|
          advice = replacement ? "; use #{replacement} instead" : ""
          warn "Shout::Configuration##{name}= is obsolete in libshout#{advice}", category: :deprecated, uplevel: 1
          super(value)
        end
      end
    end)

    def nonblocking?
      nonblocking == :none
    end

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

    # Base for settings that libshout stores as string key/value pairs. Each
    # subclass names its getter and setter function and its known keys; every
    # known key gets a reader and a writer, and any key works with [] / []=.
    class KeyValueSettings < ConfigurationBase
      def self.settings(getter:, setter:, **keys)
        define_method(:[]) do |key|
          Native.public_send(getter, shout, key.to_s)
        end

        define_method(:[]=) do |key, value|
          Error.check_error(Native.public_send(setter, shout, key.to_s, value&.to_s), shout)
        end

        keys.each { |name, key| define_key_accessors(name, key) }
      end

      def self.define_key_accessors(name, key)
        define_method(name) { self[key] }
        define_method(:"#{name}=") { |value| self[key] = value }
      end
      private_class_method :define_key_accessors
    end

    # Audio parameters advertised to the server (shout_set_audio_info).
    class AudioInfo < KeyValueSettings
      settings getter: :shout_get_audio_info, setter: :shout_set_audio_info,
               bitrate: SHOUT_AI_BITRATE,
               samplerate: SHOUT_AI_SAMPLERATE,
               channels: SHOUT_AI_CHANNELS,
               quality: SHOUT_AI_QUALITY
    end

    # Stream description such as name, genre and URL (shout_set_meta).
    class Meta < KeyValueSettings
      settings getter: :shout_get_meta, setter: :shout_set_meta,
               name: SHOUT_META_NAME,
               url: SHOUT_META_URL,
               genre: SHOUT_META_GENRE,
               description: SHOUT_META_DESCRIPTION,
               irc: SHOUT_META_IRC,
               aim: SHOUT_META_AIM,
               icq: SHOUT_META_ICQ
    end

    # Content format, usage and codecs of the stream (shout_set_content_format).
    class ContentFormat < ConfigurationBase
      def set(format, usage = SHOUT_USAGE_AUDIO, codecs = nil)
        format = Delegation::TypeConvertor.convert(format)
        Error.check_error(Native.shout_set_content_format(shout, format, usage, codecs), shout)
        self
      end

      # The format as a symbol such as :mp3 (or the raw value if unknown).
      def format
        value = info[0]
        Native.enum_type(:shout_format)[value] || value
      end

      def usage
        info[1]
      end

      def codecs
        info[2]
      end

      private

      def info
        format_ptr = FFI::MemoryPointer.new(:uint)
        usage_ptr  = FFI::MemoryPointer.new(:uint)
        codecs_ptr = FFI::MemoryPointer.new(:pointer)

        ret = Native.shout_get_content_format(shout, format_ptr, usage_ptr, codecs_ptr)
        Error.check_error(ret, shout)

        c_str_ptr = codecs_ptr.read_pointer
        codecs_str = c_str_ptr.null? ? nil : c_str_ptr.read_string

        [format_ptr.read_uint, usage_ptr.read_uint, codecs_str]
      end
    end
  end
end

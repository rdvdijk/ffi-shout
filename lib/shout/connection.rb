module Shout
  class Connection

    attr_reader :shout

    # Seconds to wait for the server when updating metadata over HTTP.
    attr_writer :metadata_timeout

    def metadata_timeout
      @metadata_timeout || HttpMetadata::DEFAULT_TIMEOUT
    end

    def self.open(*args, &block)
      connection = new(*args)
      if block_given?
        connection.connect(&block)
      else
        connection.connect
        connection
      end
    end

    def initialize(attributes = {})
      @shout = FFI::Shout.new

      attributes.each do |key, value|
        if configuration.respond_to?(:"#{key}=")
          configuration.public_send(:"#{key}=", value)
        end
      end

      yield self if block_given?
    end

    def configure
      yield configuration
      self
    end

    def configuration
      @configuration ||= Configuration.new(shout)
    end

    def connect
      ret = ::Shout.shout_open(shout)
      Error.check_error(ret, shout)

      if block_given?
        begin
          yield self
        ensure
          disconnect
        end
      else
        self
      end
    end
    alias_method :open, :connect

    def disconnect
      ret = ::Shout.shout_close(shout)
      Error.check_error(ret, shout) if ret < 0 && ret != SHOUTERR_UNCONNECTED
      ret
    end
    alias_method :close, :disconnect

    def connected?
      ::Shout.shout_get_connected(shout) == SHOUTERR_CONNECTED
    end

    def send_data(data)
      data_str = data.to_s
      len = data_str.bytesize

      ptr = ::FFI::MemoryPointer.new(:char, len)
      ptr.put_bytes(0, data_str)
      ret = ::Shout.shout_send(shout, ptr, len)
      Error.check_error(ret, shout) if ret < 0
      ret
    end
    alias_method :send, :send_data
    alias_method :write, :send_data
    alias_method :<<, :send_data

    def send_raw(data)
      data_str = data.to_s
      len = data_str.bytesize

      ptr = ::FFI::MemoryPointer.new(:char, len)
      ptr.put_bytes(0, data_str)
      ret = ::Shout.shout_send_raw(shout, ptr, len)
      Error.check_error(ret, shout) if ret < 0
      ret
    end

    def queuelen
      ret = ::Shout.shout_queuelen(shout)
      Error.check_error(ret, shout) if ret < 0
      ret
    end

    def sync
      ::Shout.shout_sync(shout)
    end

    def delay
      ret = ::Shout.shout_delay(shout)
      Error.check_error(ret, shout) if ret < 0
      ret
    end

    def send_metadata(metadata_or_hash)
      raise UnconnectedError, "Cannot send metadata to an unconnected stream" unless connected?

      metadata = case metadata_or_hash
                 when Metadata
                   metadata_or_hash
                 when Hash
                   Metadata.new(metadata_or_hash)
                 when String
                   Metadata.new("song" => metadata_or_hash)
                 else
                   raise ArgumentError, "Expected Metadata, Hash, or String, got #{metadata_or_hash.class}"
                 end

      if http_protocol?
        # libshout's own HTTP metadata update can loop forever; see HttpMetadata.
        HttpMetadata.new(configuration, timeout: metadata_timeout).update(metadata)
      else
        ret = ::Shout.shout_set_metadata_utf8(shout, metadata.metadata_struct)
        Error.check_error(ret, shout)
      end
      metadata
    end
    alias_method :update_metadata, :send_metadata
    alias_method :metadata=, :send_metadata

    def error
      ::Shout.shout_get_error(shout)
    end

    def http_protocol?
      configuration.protocol == SHOUT_PROTOCOL_HTTP
    end

    def errno
      ::Shout.shout_get_errno(shout)
    end

  end

  # Alias Client to Connection for convenience
  Client = Connection
end

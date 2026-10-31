# frozen_string_literal: true

module Shout
  # A source connection to an Icecast server: configure it, connect, send
  # audio data and update the stream's metadata.
  class Connection
    attr_reader :shout

    # Seconds to wait for the server when updating metadata over HTTP.
    attr_writer :metadata_timeout

    def metadata_timeout
      @metadata_timeout || HttpMetadata::DEFAULT_TIMEOUT
    end

    def self.open(**, &)
      connection = new(**)
      if block_given?
        connection.connect(&)
      else
        connection.connect
        connection
      end
    end

    # Creates a connection, optionally setting configuration attributes, e.g.
    # Connection.new(host: "localhost", port: 8000, mount: "/live.mp3").
    # Raises ArgumentError for attributes the configuration doesn't have.
    def initialize(**attributes)
      @shout = FFI::Shout.new
      assign_attributes(attributes)

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
    alias open connect

    def disconnect
      ret = ::Shout.shout_close(shout)
      Error.check_error(ret, shout) unless ret == SHOUTERR_UNCONNECTED
      ret
    end
    alias close disconnect

    def connected?
      ::Shout.shout_get_connected(shout) == SHOUTERR_CONNECTED
    end

    def send_data(data)
      data_str = data.to_s
      len = data_str.bytesize

      ptr = ::FFI::MemoryPointer.new(:char, len)
      ptr.put_bytes(0, data_str)
      ret = ::Shout.shout_send(shout, ptr, len)
      Error.check_error(ret, shout)
      ret
    end
    alias write send_data
    alias << send_data

    def send_raw(data)
      data_str = data.to_s
      len = data_str.bytesize

      ptr = ::FFI::MemoryPointer.new(:char, len)
      ptr.put_bytes(0, data_str)
      ret = ::Shout.shout_send_raw(shout, ptr, len)
      Error.check_error(ret, shout)
      ret
    end

    def queuelen
      ret = ::Shout.shout_queuelen(shout)
      Error.check_error(ret, shout)
      ret
    end

    def sync
      ::Shout.shout_sync(shout)
    end

    def delay
      ret = ::Shout.shout_delay(shout)
      Error.check_error(ret, shout)
      ret
    end

    def send_metadata(metadata_or_hash)
      raise UnconnectedError, "Cannot send metadata to an unconnected stream" unless connected?

      metadata = coerce_metadata(metadata_or_hash)
      if http_protocol?
        # libshout's own HTTP metadata update can loop forever; see HttpMetadata.
        HttpMetadata.new(configuration, timeout: metadata_timeout).update(metadata)
      else
        ret = ::Shout.shout_set_metadata_utf8(shout, metadata.metadata_struct)
        Error.check_error(ret, shout)
      end
      metadata
    end
    alias update_metadata send_metadata
    alias metadata= send_metadata

    def error
      ::Shout.shout_get_error(shout)
    end

    def http_protocol?
      configuration.protocol == SHOUT_PROTOCOL_HTTP
    end

    def errno
      ::Shout.shout_get_errno(shout)
    end

    private

    def assign_attributes(attributes)
      unknown = attributes.keys.reject { |key| configuration.respond_to?(:"#{key}=") }
      raise ArgumentError, "unknown attribute(s): #{unknown.join(", ")}" if unknown.any?

      attributes.each { |key, value| configuration.public_send(:"#{key}=", value) }
    end

    def coerce_metadata(value)
      case value
      when Metadata then value
      when Hash then Metadata.new(value)
      when String then Metadata.new("song" => value)
      else raise ArgumentError, "Expected Metadata, Hash, or String, got #{value.class}"
      end
    end
  end

  # Alias Client to Connection for convenience
  Client = Connection
end

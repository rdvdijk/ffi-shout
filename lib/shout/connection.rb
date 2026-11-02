# frozen_string_literal: true

module Shout
  # A source connection to an Icecast server: configure it, connect, send
  # audio data and update the stream's metadata.
  #
  # Commands (disconnect, send_data, sync, configure) return the connection,
  # so they can be chained: `connection << chunk1 << chunk2`.
  class Connection
    attr_reader :shout

    # Seconds to wait for the server when updating metadata over HTTP.
    attr_writer :metadata_timeout

    def metadata_timeout
      @metadata_timeout || HttpMetadata::DEFAULT_TIMEOUT
    end

    # Creates a connection and connects. With a block, yields the connection,
    # disconnects afterwards and returns the block's value.
    def self.open(**, &)
      new(**).connect(&)
    end

    # Creates a connection, optionally setting configuration attributes, e.g.
    # Connection.new(host: "localhost", port: 8000, mount: "/live.mp3").
    # Raises ArgumentError for attributes the configuration doesn't have.
    def initialize(**attributes)
      @shout = Native.shout_new
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

    # Connects to the server. Without a block, returns the connection. With a
    # block, yields the connection, disconnects afterwards (also when the
    # block raises) and returns the block's value.
    def connect
      Error.check_error(Native.shout_open(shout), shout)
      return self unless block_given?

      begin
        yield self
      ensure
        disconnect
      end
    end
    alias open connect

    # Disconnects; does nothing when not connected.
    def disconnect
      ret = Native.shout_close(shout)
      Error.check_error(ret, shout) unless ret == SHOUTERR_UNCONNECTED
      self
    end
    alias close disconnect

    def connected?
      Native.shout_get_connected(shout) == SHOUTERR_CONNECTED
    end

    # Sends audio data, which libshout parses for timing information.
    def send_data(data)
      with_buffer(data) { |ptr, len| Error.check_error(Native.shout_send(shout, ptr, len), shout) }
      self
    end
    alias write send_data
    alias << send_data

    # Sends data without parsing it. Returns the number of bytes written.
    def send_raw(data)
      with_buffer(data) do |ptr, len|
        Native.shout_send_raw(shout, ptr, len).tap { |ret| Error.check_error(ret, shout) }
      end
    end

    # Number of bytes waiting in the send queue (only useful in nonblocking mode).
    def queuelen
      Native.shout_queuelen(shout).tap { |ret| Error.check_error(ret, shout) }
    end

    # Sleeps until it is time to send more data.
    def sync
      Native.shout_sync(shout)
      self
    end

    # Milliseconds to wait before sending more data.
    def delay
      Native.shout_delay(shout)
    end

    # Updates the stream's metadata. Accepts a Metadata, a Hash or a String
    # (used as the "song" value). Returns the Metadata that was sent.
    def send_metadata(metadata_or_hash)
      raise UnconnectedError, "Cannot send metadata to an unconnected stream" unless connected?

      metadata = coerce_metadata(metadata_or_hash)
      if http_protocol?
        # libshout's own HTTP metadata update can loop forever; see HttpMetadata.
        HttpMetadata.new(configuration, timeout: metadata_timeout).update(metadata)
      else
        Error.check_error(Native.shout_set_metadata_utf8(shout, metadata.handle), shout)
      end
      metadata
    end
    alias update_metadata send_metadata
    alias metadata= send_metadata

    def error
      Native.shout_get_error(shout)
    end

    def errno
      Native.shout_get_errno(shout)
    end

    private

    def http_protocol?
      configuration.protocol == :http
    end

    # Copies +data+ into native memory for the duration of the block. libshout
    # calls release the GVL, so they must not read a Ruby string's memory.
    def with_buffer(data)
      bytes = data.to_s
      ptr = FFI::MemoryPointer.new(:char, bytes.bytesize)
      ptr.put_bytes(0, bytes)
      yield ptr, bytes.bytesize
    end

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

  Client = Connection
end

# frozen_string_literal: true

# Exception classes raised for libshout errors.
module Shout
  class ShoutError < StandardError; end

  class ConfigurationError < ShoutError; end
  class InsaneError < ShoutError; end
  class ConnectionError < ShoutError; end
  class LoginError < ShoutError; end
  # SHOUTERR_SOCKET: an error while reading from or writing to the server.
  class SocketIOError < ShoutError; end
  class MallocError < ShoutError; end
  class MetadataError < ShoutError; end
  class ConnectedError < ShoutError; end
  class UnconnectedError < ShoutError; end
  class UnsupportedError < ShoutError; end
  class BusyError < ShoutError; end
  class NoTLSError < ShoutError; end
  class TLSBadCertError < ShoutError; end
  class RetryError < ShoutError; end

  # Deprecated: use SocketIOError. Inside `module Shout` this name hid Ruby's
  # own ::SocketError; it will be removed in a future release.
  SocketError = SocketIOError
  deprecate_constant :SocketError

  # Maps libshout's SHOUTERR_* return codes to exception classes.
  module Error
    ERROR_CLASSES = {
      -1 => InsaneError,
      -2 => ConnectionError,
      -3 => LoginError,
      -4 => SocketIOError,
      -5 => MallocError,
      -6 => MetadataError,
      -7 => ConnectedError,
      -8 => UnconnectedError,
      -9 => UnsupportedError,
      -10 => BusyError,
      -11 => NoTLSError,
      -12 => TLSBadCertError,
      -13 => RetryError
    }.freeze

    # Raises the Shout::ShoutError subclass for a negative libshout return
    # code, using libshout's own error text when +shout_ptr+ is given. Does
    # nothing for success codes (>= 0) and non-Integer values.
    def self.check_error(return_code, shout_ptr = nil)
      return unless return_code.is_a?(Integer) && return_code.negative?

      error_class = ERROR_CLASSES.fetch(return_code, ShoutError)
      raise error_class, libshout_message(shout_ptr) || "libshout error code #{return_code}"
    end

    def self.libshout_message(shout_ptr)
      ptr = shout_ptr.respond_to?(:to_ptr) ? shout_ptr.to_ptr : shout_ptr
      return if ptr.nil? || ptr.null?

      message = Shout.shout_get_error(ptr)
      message unless message.nil? || message.empty?
    rescue StandardError
      nil # fall back to the generic message
    end
    private_class_method :libshout_message
  end
end

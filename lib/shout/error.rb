# frozen_string_literal: true

# Exception classes for libshout errors.
module Shout
  class ShoutError < StandardError; end

  class InsaneError < ShoutError; end
  class ConnectionError < ShoutError; end
  class LoginError < ShoutError; end
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

  # Maps libshout's SHOUTERR_* return codes to exception classes.
  module Error
    ERROR_CLASSES = {
      SHOUTERR_INSANE => InsaneError,
      SHOUTERR_NOCONNECT => ConnectionError,
      SHOUTERR_NOLOGIN => LoginError,
      SHOUTERR_SOCKET => SocketIOError,
      SHOUTERR_MALLOC => MallocError,
      SHOUTERR_METADATA => MetadataError,
      SHOUTERR_CONNECTED => ConnectedError,
      SHOUTERR_UNCONNECTED => UnconnectedError,
      SHOUTERR_UNSUPPORTED => UnsupportedError,
      SHOUTERR_BUSY => BusyError,
      SHOUTERR_NOTLS => NoTLSError,
      SHOUTERR_TLSBADCERT => TLSBadCertError,
      SHOUTERR_RETRY => RetryError
    }.freeze

    # Raises the matching ShoutError for a negative libshout return code.
    def self.check_error(return_code, shout_ptr = nil)
      return unless return_code.is_a?(Integer) && return_code.negative?

      error_class = ERROR_CLASSES.fetch(return_code, ShoutError)
      raise error_class, libshout_message(shout_ptr) || "libshout error code #{return_code}"
    end

    def self.libshout_message(shout_ptr)
      ptr = shout_ptr.respond_to?(:to_ptr) ? shout_ptr.to_ptr : shout_ptr
      return if ptr.nil? || ptr.null?

      message = Native.shout_get_error(ptr)
      message unless message.nil? || message.empty?
    rescue StandardError
      nil
    end
    private_class_method :libshout_message
  end
end

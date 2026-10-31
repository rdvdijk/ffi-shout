module Shout

  class ShoutError < StandardError; end

  class ConfigurationError < ShoutError; end
  class InsaneError < ShoutError; end
  class ConnectionError < ShoutError; end
  class LoginError < ShoutError; end
  class SocketError < ShoutError; end
  class MallocError < ShoutError; end
  class MetadataError < ShoutError; end
  class ConnectedError < ShoutError; end
  class UnconnectedError < ShoutError; end
  class UnsupportedError < ShoutError; end
  class BusyError < ShoutError; end
  class NoTLSError < ShoutError; end
  class TLSBadCertError < ShoutError; end
  class RetryError < ShoutError; end

  module Error
    ERROR_CLASSES = {
      -1  => InsaneError,
      -2  => ConnectionError,
      -3  => LoginError,
      -4  => SocketError,
      -5  => MallocError,
      -6  => MetadataError,
      -7  => ConnectedError,
      -8  => UnconnectedError,
      -9  => UnsupportedError,
      -10 => BusyError,
      -11 => NoTLSError,
      -12 => TLSBadCertError,
      -13 => RetryError
    }.freeze

    def self.check_error(return_code, shout_ptr = nil)
      return if return_code >= 0

      error_class = ERROR_CLASSES[return_code] || ShoutError
      message = nil

      if shout_ptr
        begin
          ptr = shout_ptr.respond_to?(:to_ptr) ? shout_ptr.to_ptr : shout_ptr
          if ptr && !ptr.null?
            err = Shout.shout_get_error(ptr)
            message = err if err && !err.empty?
          end
        rescue StandardError
          # Fallback to default message
        end
      end

      message ||= "libshout error code #{return_code}"
      raise error_class, message
    end
  end

end

# frozen_string_literal: true

require "net/http"
require "openssl"
require "uri"

module Shout
  # Updates a mount's metadata through Icecast's +/admin/metadata+ endpoint,
  # sending the source credentials with the very first request.
  #
  # This replaces +shout_set_metadata_utf8+ for the HTTP protocol. libshout
  # 2.4.6 first sends the request without credentials and then reuses a
  # socket that Icecast 2.5 has already closed after its 401. The empty reply
  # starts libshout's "GET /admin/!POKE" TLS probe, Icecast answers 400 and
  # closes again, and libshout retries forever without ever returning. See
  # https://gitlab.xiph.org/xiph/icecast-libshout/-/issues/2341
  class HttpMetadata
    PATH            = "/admin/metadata"
    DEFAULT_TIMEOUT = 5

    PLAIN_TLS_MODES = [SHOUT_TLS_DISABLED, SHOUT_TLS_AUTO].freeze

    NETWORK_ERRORS = [
      Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH,
      Errno::ENETUNREACH, Errno::EPIPE, EOFError, IOError,
      Net::OpenTimeout, Net::ReadTimeout, ::SocketError, OpenSSL::SSL::SSLError
    ].freeze

    attr_reader :configuration, :timeout

    def initialize(configuration, timeout: DEFAULT_TIMEOUT)
      @configuration = configuration
      @timeout = timeout
    end

    # Sends +metadata+ (a Shout::Metadata) for the configured mount. Returns
    # the server's response message, or raises a Shout::ShoutError.
    def update(metadata)
      handle_response(http.request(build_request(metadata)))
    rescue *NETWORK_ERRORS => e
      raise ConnectionError, "Metadata update failed: #{e.class}: #{e.message}"
    end

    private

    def build_request(metadata)
      request = Net::HTTP::Get.new("#{PATH}?#{query(metadata)}")
      request.basic_auth(configuration.user.to_s, configuration.password.to_s)
      request["User-Agent"] = configuration.agent if configuration.agent
      request
    end

    def query(metadata)
      params = [%w[mode updinfo], %w[charset UTF-8], ["mount", configuration.mount.to_s]]
      params.concat(metadata.to_h.to_a)
      params.map { |key, value| "#{encode(key)}=#{encode(value)}" }.join("&")
    end

    def encode(value)
      URI.encode_uri_component(value.to_s)
    end

    def http
      http = Net::HTTP.new(configuration.host, configuration.port)
      http.open_timeout = timeout
      http.read_timeout = timeout
      http.write_timeout = timeout
      configure_tls(http)
      http
    end

    def configure_tls(http)
      mode = configuration.tls
      return if PLAIN_TLS_MODES.include?(mode)

      unless mode == SHOUT_TLS_RFC2818
        raise UnsupportedError, "TLS mode #{mode} is not supported for HTTP metadata updates; use :rfc2818 or :disabled"
      end

      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      configure_ca(http)
    end

    def configure_ca(http)
      http.ca_file = configuration.ca_file if configuration.ca_file
      http.ca_path = configuration.ca_directory if configuration.ca_directory
    end

    def handle_response(response)
      body = response.body.to_s
      message = body[%r{<message>(.*?)</message>}m, 1]
      detail = "HTTP #{response.code}#{": #{message}" if message}"

      if response.is_a?(Net::HTTPUnauthorized) || response.is_a?(Net::HTTPForbidden)
        raise LoginError, "Metadata update rejected (#{detail})"
      end
      return message if response.is_a?(Net::HTTPSuccess) && body.include?("<return>1</return>")

      raise MetadataError, "Metadata update failed (#{detail})"
    end
  end
end

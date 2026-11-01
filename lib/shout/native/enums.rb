# frozen_string_literal: true

module Shout
  # FFI enum types for the libshout constants in Shout (see constants.rb).
  # Functions that take or return these values are attached with the enum
  # type, so they accept and return symbols such as :mp3 or :http.
  module Native
    enum :shout_error, [
      :success,      SHOUTERR_SUCCESS,
      :insane,       SHOUTERR_INSANE,
      :noconnect,    SHOUTERR_NOCONNECT,
      :nologin,      SHOUTERR_NOLOGIN,
      :socket,       SHOUTERR_SOCKET,
      :malloc,       SHOUTERR_MALLOC,
      :metadata,     SHOUTERR_METADATA,
      :connected,    SHOUTERR_CONNECTED,
      :unconnected,  SHOUTERR_UNCONNECTED,
      :unsupported,  SHOUTERR_UNSUPPORTED,
      :busy,         SHOUTERR_BUSY,
      :notls,        SHOUTERR_NOTLS,
      :tlsbadcert,   SHOUTERR_TLSBADCERT,
      :retry,        SHOUTERR_RETRY
    ]

    enum :shout_format, [
      :ogg,        SHOUT_FORMAT_OGG,
      :mp3,        SHOUT_FORMAT_MP3,
      :webm,       SHOUT_FORMAT_WEBM,
      :webmaudio,  SHOUT_FORMAT_WEBMAUDIO,
      :matroska,   SHOUT_FORMAT_MATROSKA,
      :text,       SHOUT_FORMAT_TEXT
    ]

    enum :shout_protocol, [
      :http,        SHOUT_PROTOCOL_HTTP,
      :xaudiocast,  SHOUT_PROTOCOL_XAUDIOCAST,
      :icy,         SHOUT_PROTOCOL_ICY,
      :roaraudio,   SHOUT_PROTOCOL_ROARAUDIO
    ]

    enum :shout_tls, [
      :disabled,       SHOUT_TLS_DISABLED,
      :auto,           SHOUT_TLS_AUTO,
      :auto_no_plain,  SHOUT_TLS_AUTO_NO_PLAIN,
      :rfc2818,        SHOUT_TLS_RFC2818,
      :rfc2817,        SHOUT_TLS_RFC2817
    ]

    enum :shout_blocking, [
      :full,    SHOUT_BLOCKING_FULL,
      :none,    SHOUT_BLOCKING_NONE,
      :default, SHOUT_BLOCKING_DEFAULT
    ]

    enum :shout_control_t, [
      :control_min,                                   0,
      :control_get_server_certificate_as_pem,         1,
      :control_get_server_certificate_chain_as_pem,   2,
      :control_max, 32_767
    ]

    enum :shout_event_t, [
      :event_min, 0,
      :event_tls_check_peer_certificate, 1,
      :event_max, 32_767
    ]
  end
end

# frozen_string_literal: true

# The integer and string constants from shout.h. They are public: settings
# accept them as well as symbols (e.g. SHOUT_USAGE_AUDIO for set_content_format).
module Shout
  SHOUTERR_SUCCESS = 0
  SHOUTERR_INSANE             = -1
  SHOUTERR_NOCONNECT          = -2
  SHOUTERR_NOLOGIN            = -3
  SHOUTERR_SOCKET             = -4
  SHOUTERR_MALLOC             = -5
  SHOUTERR_METADATA           = -6
  SHOUTERR_CONNECTED          = -7
  SHOUTERR_UNCONNECTED        = -8
  SHOUTERR_UNSUPPORTED        = -9
  SHOUTERR_BUSY               = -10
  SHOUTERR_NOTLS              = -11
  SHOUTERR_TLSBADCERT         = -12
  SHOUTERR_RETRY              = -13

  SHOUT_FORMAT_OGG            = 0
  SHOUT_FORMAT_MP3            = 1
  SHOUT_FORMAT_WEBM           = 2
  SHOUT_FORMAT_WEBMAUDIO      = 3
  SHOUT_FORMAT_MATROSKA       = 4
  SHOUT_FORMAT_TEXT           = 5
  SHOUT_FORMAT_VORBIS         = SHOUT_FORMAT_OGG

  SHOUT_USAGE_AUDIO           = 0x0001
  SHOUT_USAGE_VISUAL          = 0x0002
  SHOUT_USAGE_TEXT            = 0x0004
  SHOUT_USAGE_SUBTITLE        = 0x0008
  SHOUT_USAGE_LIGHT           = 0x0010
  SHOUT_USAGE_UI              = 0x0020
  SHOUT_USAGE_METADATA        = 0x0040
  SHOUT_USAGE_APPLICATION     = 0x0080
  SHOUT_USAGE_CONTROL         = 0x0100
  SHOUT_USAGE_COMPLEX         = 0x0200
  SHOUT_USAGE_OTHER           = 0x0400
  SHOUT_USAGE_UNKNOWN         = 0x0800
  SHOUT_USAGE_3D              = 0x1000
  SHOUT_USAGE_4D              = 0x2000

  SHOUT_PROTOCOL_HTTP         = 0
  SHOUT_PROTOCOL_XAUDIOCAST   = 1
  SHOUT_PROTOCOL_ICY          = 2
  SHOUT_PROTOCOL_ROARAUDIO    = 3

  SHOUT_TLS_DISABLED          = 0
  SHOUT_TLS_AUTO              = 1
  SHOUT_TLS_AUTO_NO_PLAIN     = 2
  SHOUT_TLS_RFC2818           = 11
  SHOUT_TLS_RFC2817           = 12

  SHOUT_BLOCKING_DEFAULT      = 255
  SHOUT_BLOCKING_FULL         = 0
  SHOUT_BLOCKING_NONE         = 1

  SHOUT_AI_BITRATE            = "bitrate"
  SHOUT_AI_SAMPLERATE         = "samplerate"
  SHOUT_AI_CHANNELS           = "channels"
  SHOUT_AI_QUALITY            = "quality"

  SHOUT_META_NAME             = "name"
  SHOUT_META_URL              = "url"
  SHOUT_META_GENRE            = "genre"
  SHOUT_META_DESCRIPTION      = "description"
  SHOUT_META_IRC              = "irc"
  SHOUT_META_AIM              = "aim"
  SHOUT_META_ICQ              = "icq"

  SHOUT_CALLBACK_PASS         = 1

  SHOUT_THREADSAFE            = 1
  SHOUT_TLS                   = 1
end

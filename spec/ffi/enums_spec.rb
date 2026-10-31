require 'spec_helper'

module Shout
  describe FFI::Enums do
    describe "Constants" do
      it "defines error constants" do
        expect(SHOUTERR_SUCCESS).to eql 0
        expect(SHOUTERR_INSANE).to eql(-1)
        expect(SHOUTERR_NOCONNECT).to eql(-2)
        expect(SHOUTERR_NOLOGIN).to eql(-3)
        expect(SHOUTERR_SOCKET).to eql(-4)
        expect(SHOUTERR_MALLOC).to eql(-5)
        expect(SHOUTERR_METADATA).to eql(-6)
        expect(SHOUTERR_CONNECTED).to eql(-7)
        expect(SHOUTERR_UNCONNECTED).to eql(-8)
        expect(SHOUTERR_UNSUPPORTED).to eql(-9)
        expect(SHOUTERR_BUSY).to eql(-10)
        expect(SHOUTERR_NOTLS).to eql(-11)
        expect(SHOUTERR_TLSBADCERT).to eql(-12)
        expect(SHOUTERR_RETRY).to eql(-13)
      end

      it "defines format constants" do
        expect(SHOUT_FORMAT_OGG).to eql 0
        expect(SHOUT_FORMAT_MP3).to eql 1
        expect(SHOUT_FORMAT_WEBM).to eql 2
        expect(SHOUT_FORMAT_WEBMAUDIO).to eql 3
        expect(SHOUT_FORMAT_MATROSKA).to eql 4
        expect(SHOUT_FORMAT_TEXT).to eql 5
        expect(SHOUT_FORMAT_VORBIS).to eql 0
      end

      it "defines usage constants" do
        expect(SHOUT_USAGE_AUDIO).to eql 0x0001
        expect(SHOUT_USAGE_VISUAL).to eql 0x0002
        expect(SHOUT_USAGE_TEXT).to eql 0x0004
        expect(SHOUT_USAGE_SUBTITLE).to eql 0x0008
        expect(SHOUT_USAGE_LIGHT).to eql 0x0010
        expect(SHOUT_USAGE_UI).to eql 0x0020
        expect(SHOUT_USAGE_METADATA).to eql 0x0040
        expect(SHOUT_USAGE_APPLICATION).to eql 0x0080
        expect(SHOUT_USAGE_CONTROL).to eql 0x0100
        expect(SHOUT_USAGE_COMPLEX).to eql 0x0200
        expect(SHOUT_USAGE_OTHER).to eql 0x0400
        expect(SHOUT_USAGE_UNKNOWN).to eql 0x0800
        expect(SHOUT_USAGE_3D).to eql 0x1000
        expect(SHOUT_USAGE_4D).to eql 0x2000
      end

      it "defines protocol constants" do
        expect(SHOUT_PROTOCOL_HTTP).to eql 0
        expect(SHOUT_PROTOCOL_XAUDIOCAST).to eql 1
        expect(SHOUT_PROTOCOL_ICY).to eql 2
        expect(SHOUT_PROTOCOL_ROARAUDIO).to eql 3
      end

      it "defines TLS mode constants" do
        expect(SHOUT_TLS_DISABLED).to eql 0
        expect(SHOUT_TLS_AUTO).to eql 1
        expect(SHOUT_TLS_AUTO_NO_PLAIN).to eql 2
        expect(SHOUT_TLS_RFC2818).to eql 11
        expect(SHOUT_TLS_RFC2817).to eql 12
      end

      it "defines blocking mode constants" do
        expect(SHOUT_BLOCKING_DEFAULT).to eql 255
        expect(SHOUT_BLOCKING_FULL).to eql 0
        expect(SHOUT_BLOCKING_NONE).to eql 1
      end

      it "defines audio info string constants" do
        expect(SHOUT_AI_BITRATE).to eql "bitrate"
        expect(SHOUT_AI_SAMPLERATE).to eql "samplerate"
        expect(SHOUT_AI_CHANNELS).to eql "channels"
        expect(SHOUT_AI_QUALITY).to eql "quality"
      end

      it "defines meta string constants" do
        expect(SHOUT_META_NAME).to eql "name"
        expect(SHOUT_META_URL).to eql "url"
        expect(SHOUT_META_GENRE).to eql "genre"
        expect(SHOUT_META_DESCRIPTION).to eql "description"
        expect(SHOUT_META_IRC).to eql "irc"
        expect(SHOUT_META_AIM).to eql "aim"
        expect(SHOUT_META_ICQ).to eql "icq"
      end

      it "defines compiled features constants" do
        expect(SHOUT_THREADSAFE).to eql 1
        expect(SHOUT_TLS).to eql 1
      end
    end

    describe "FFI Enums" do
      it "maps shout_error enum" do
        expect(::Shout.enum_type(:shout_error)).to be_a(::FFI::Enum)
        expect(::Shout.enum_type(:shout_error)[:success]).to eql 0
      end

      it "maps shout_format enum" do
        expect(::Shout.enum_type(:shout_format)).to be_a(::FFI::Enum)
        expect(::Shout.enum_type(:shout_format)[:mp3]).to eql 1
      end

      it "maps shout_protocol enum" do
        expect(::Shout.enum_type(:shout_protocol)).to be_a(::FFI::Enum)
        expect(::Shout.enum_type(:shout_protocol)[:http]).to eql 0
      end

      it "maps shout_tls enum" do
        expect(::Shout.enum_type(:shout_tls)).to be_a(::FFI::Enum)
        expect(::Shout.enum_type(:shout_tls)[:auto]).to eql 1
      end

      it "maps shout_blocking enum" do
        expect(::Shout.enum_type(:shout_blocking)).to be_a(::FFI::Enum)
        expect(::Shout.enum_type(:shout_blocking)[:none]).to eql 1
      end

      it "maps shout_control_t enum" do
        expect(::Shout.enum_type(:shout_control_t)).to be_a(::FFI::Enum)
      end

      it "maps shout_event_t enum" do
        expect(::Shout.enum_type(:shout_event_t)).to be_a(::FFI::Enum)
      end
    end
  end
end

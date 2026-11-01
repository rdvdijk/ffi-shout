# frozen_string_literal: true

module Shout
  RSpec.describe Native do
    describe "Constants" do
      it "defines error constants" do
        expect(SHOUTERR_SUCCESS).to be 0
        expect(SHOUTERR_INSANE).to be(-1)
        expect(SHOUTERR_NOCONNECT).to be(-2)
        expect(SHOUTERR_NOLOGIN).to be(-3)
        expect(SHOUTERR_SOCKET).to be(-4)
        expect(SHOUTERR_MALLOC).to be(-5)
        expect(SHOUTERR_METADATA).to be(-6)
        expect(SHOUTERR_CONNECTED).to be(-7)
        expect(SHOUTERR_UNCONNECTED).to be(-8)
        expect(SHOUTERR_UNSUPPORTED).to be(-9)
        expect(SHOUTERR_BUSY).to be(-10)
        expect(SHOUTERR_NOTLS).to be(-11)
        expect(SHOUTERR_TLSBADCERT).to be(-12)
        expect(SHOUTERR_RETRY).to be(-13)
      end

      it "defines format constants" do
        expect(SHOUT_FORMAT_OGG).to be 0
        expect(SHOUT_FORMAT_MP3).to be 1
        expect(SHOUT_FORMAT_WEBM).to be 2
        expect(SHOUT_FORMAT_WEBMAUDIO).to be 3
        expect(SHOUT_FORMAT_MATROSKA).to be 4
        expect(SHOUT_FORMAT_TEXT).to be 5
        expect(SHOUT_FORMAT_VORBIS).to be 0
      end

      it "defines usage constants" do
        expect(SHOUT_USAGE_AUDIO).to be 0x0001
        expect(SHOUT_USAGE_VISUAL).to be 0x0002
        expect(SHOUT_USAGE_TEXT).to be 0x0004
        expect(SHOUT_USAGE_SUBTITLE).to be 0x0008
        expect(SHOUT_USAGE_LIGHT).to be 0x0010
        expect(SHOUT_USAGE_UI).to be 0x0020
        expect(SHOUT_USAGE_METADATA).to be 0x0040
        expect(SHOUT_USAGE_APPLICATION).to be 0x0080
        expect(SHOUT_USAGE_CONTROL).to be 0x0100
        expect(SHOUT_USAGE_COMPLEX).to be 0x0200
        expect(SHOUT_USAGE_OTHER).to be 0x0400
        expect(SHOUT_USAGE_UNKNOWN).to be 0x0800
        expect(SHOUT_USAGE_3D).to be 0x1000
        expect(SHOUT_USAGE_4D).to be 0x2000
      end

      it "defines protocol constants" do
        expect(SHOUT_PROTOCOL_HTTP).to be 0
        expect(SHOUT_PROTOCOL_XAUDIOCAST).to be 1
        expect(SHOUT_PROTOCOL_ICY).to be 2
        expect(SHOUT_PROTOCOL_ROARAUDIO).to be 3
      end

      it "defines TLS mode constants" do
        expect(SHOUT_TLS_DISABLED).to be 0
        expect(SHOUT_TLS_AUTO).to be 1
        expect(SHOUT_TLS_AUTO_NO_PLAIN).to be 2
        expect(SHOUT_TLS_RFC2818).to be 11
        expect(SHOUT_TLS_RFC2817).to be 12
      end

      it "defines blocking mode constants" do
        expect(SHOUT_BLOCKING_DEFAULT).to be 255
        expect(SHOUT_BLOCKING_FULL).to be 0
        expect(SHOUT_BLOCKING_NONE).to be 1
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
        expect(SHOUT_THREADSAFE).to be 1
        expect(SHOUT_TLS).to be 1
      end
    end

    describe "FFI Enums" do
      it "maps shout_error enum" do
        expect(described_class.enum_type(:shout_error)).to be_a(FFI::Enum)
        expect(described_class.enum_type(:shout_error)[:success]).to be 0
      end

      it "maps shout_format enum" do
        expect(described_class.enum_type(:shout_format)).to be_a(FFI::Enum)
        expect(described_class.enum_type(:shout_format)[:mp3]).to be 1
      end

      it "maps shout_protocol enum" do
        expect(described_class.enum_type(:shout_protocol)).to be_a(FFI::Enum)
        expect(described_class.enum_type(:shout_protocol)[:http]).to be 0
      end

      it "maps shout_tls enum" do
        expect(described_class.enum_type(:shout_tls)).to be_a(FFI::Enum)
        expect(described_class.enum_type(:shout_tls)[:auto]).to be 1
      end

      it "maps shout_blocking enum" do
        expect(described_class.enum_type(:shout_blocking)).to be_a(FFI::Enum)
        expect(described_class.enum_type(:shout_blocking)[:none]).to be 1
      end

      it "maps shout_control_t enum" do
        expect(described_class.enum_type(:shout_control_t)).to be_a(FFI::Enum)
      end

      it "maps shout_event_t enum" do
        expect(described_class.enum_type(:shout_event_t)).to be_a(FFI::Enum)
      end
    end
  end
end

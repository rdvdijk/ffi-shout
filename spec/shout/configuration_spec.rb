# frozen_string_literal: true

module Shout
  RSpec.describe Configuration do
    let(:shout) { instance_double(::FFI::Pointer) }

    subject(:configuration) { described_class.new(shout) }

    context "initialization" do
      it "initializes with shout pointer" do
        expect(configuration.shout).to eql shout
      end

      it "initializes an AudioInfo configuration object" do
        expect(Configuration::AudioInfo).to receive(:new).with(shout)
        configuration.audio_info
      end

      it "memoizes one AudioInfo configuration object" do
        allow(Configuration::AudioInfo).to receive(:new).and_return(double)
        expect(Configuration::AudioInfo).to receive(:new).exactly(:once)
        2.times { configuration.audio_info }
      end

      it "initializes a Meta configuration object" do
        expect(Configuration::Meta).to receive(:new).with(shout)
        configuration.meta
      end

      it "memoizes one Meta configuration object" do
        allow(Configuration::Meta).to receive(:new).and_return(double)
        expect(Configuration::Meta).to receive(:new).exactly(:once)
        2.times { configuration.meta }
      end

      it "initializes a ContentFormat configuration object" do
        expect(Configuration::ContentFormat).to receive(:new).with(shout)
        configuration.content_format
      end

      it "memoizes one ContentFormat configuration object" do
        allow(Configuration::ContentFormat).to receive(:new).and_return(double)
        expect(Configuration::ContentFormat).to receive(:new).exactly(:once)
        2.times { configuration.content_format }
      end
    end

    context "set/get delegation" do
      context "alias fields" do
        it { is_expected.to delegate(:username).to(:user) }
        it { is_expected.to delegate(:pass).to(:password) }
        it { is_expected.to delegate(:mountpoint).to(:mount) }
        it { is_expected.to delegate(:user_agent).to(:agent) }
      end

      context "basic fields" do
        it { is_expected.to delegate(:host) }
        it { is_expected.to delegate(:port) }
        it { is_expected.to delegate(:agent) }
        it { is_expected.to delegate(:tls) }
        it { is_expected.to delegate(:ca_directory) }
        it { is_expected.to delegate(:ca_file) }
        it { is_expected.to delegate(:allowed_ciphers) }
        it { is_expected.to delegate(:user) }
        it { is_expected.to delegate(:password) }
        it { is_expected.to delegate(:client_certificate) }
        it { is_expected.to delegate(:mount) }
        it { is_expected.to delegate(:public) }
        it { is_expected.to delegate(:content_language) }
        it { is_expected.to delegate(:protocol) }
        it { is_expected.to delegate(:nonblocking) }

        # Obsolete fields
        it { is_expected.to delegate(:name) }
        it { is_expected.to delegate(:url) }
        it { is_expected.to delegate(:genre) }
        it { is_expected.to delegate(:description) }
        it { is_expected.to delegate(:format) }
        it { is_expected.to delegate(:dumpfile) }
      end
    end

    context "audio_info fields" do
      subject(:audio_info) { configuration.audio_info }

      it "delegates #bitrate= to shout_set_audio_info" do
        expect(::Shout).to receive(:shout_set_audio_info).with(shout, "bitrate", "128").and_return(0)
        audio_info.bitrate = 128
      end

      it "delegates #bitrate to shout_get_audio_info" do
        expect(::Shout).to receive(:shout_get_audio_info).with(shout, "bitrate").and_return("128")
        expect(audio_info.bitrate).to eql "128"
      end

      it "delegates #samplerate= to shout_set_audio_info" do
        expect(::Shout).to receive(:shout_set_audio_info).with(shout, "samplerate", "44100").and_return(0)
        audio_info.samplerate = 44_100
      end

      it "delegates #samplerate to shout_get_audio_info" do
        expect(::Shout).to receive(:shout_get_audio_info).with(shout, "samplerate").and_return("44100")
        expect(audio_info.samplerate).to eql "44100"
      end

      it "delegates #channels= to shout_set_audio_info" do
        expect(::Shout).to receive(:shout_set_audio_info).with(shout, "channels", "2").and_return(0)
        audio_info.channels = 2
      end

      it "delegates #channels to shout_get_audio_info" do
        expect(::Shout).to receive(:shout_get_audio_info).with(shout, "channels").and_return("2")
        expect(audio_info.channels).to eql "2"
      end

      it "delegates #quality= to shout_set_audio_info" do
        expect(::Shout).to receive(:shout_set_audio_info).with(shout, "quality", "5").and_return(0)
        audio_info.quality = 5
      end

      it "delegates #quality to shout_get_audio_info" do
        expect(::Shout).to receive(:shout_get_audio_info).with(shout, "quality").and_return("5")
        expect(audio_info.quality).to eql "5"
      end

      it "supports hash-like access via [] and []=" do
        expect(::Shout).to receive(:shout_set_audio_info).with(shout, "custom", "val").and_return(0)
        audio_info["custom"] = "val"

        expect(::Shout).to receive(:shout_get_audio_info).with(shout, "custom").and_return("val")
        expect(audio_info["custom"]).to eql "val"
      end
    end

    context "meta fields" do
      subject(:meta) { configuration.meta }

      it "delegates #name= to shout_set_meta" do
        expect(::Shout).to receive(:shout_set_meta).with(shout, "name", "My Station").and_return(0)
        meta.name = "My Station"
      end

      it "delegates #name to shout_get_meta" do
        expect(::Shout).to receive(:shout_get_meta).with(shout, "name").and_return("My Station")
        expect(meta.name).to eql "My Station"
      end

      it "delegates #url= to shout_set_meta" do
        expect(::Shout).to receive(:shout_set_meta).with(shout, "url", "http://example.com").and_return(0)
        meta.url = "http://example.com"
      end

      it "delegates #url to shout_get_meta" do
        expect(::Shout).to receive(:shout_get_meta).with(shout, "url").and_return("http://example.com")
        expect(meta.url).to eql "http://example.com"
      end

      it "delegates #genre= to shout_set_meta" do
        expect(::Shout).to receive(:shout_set_meta).with(shout, "genre", "Rock").and_return(0)
        meta.genre = "Rock"
      end

      it "delegates #genre to shout_get_meta" do
        expect(::Shout).to receive(:shout_get_meta).with(shout, "genre").and_return("Rock")
        expect(meta.genre).to eql "Rock"
      end

      it "delegates #description= to shout_set_meta" do
        expect(::Shout).to receive(:shout_set_meta).with(shout, "description", "Best station").and_return(0)
        meta.description = "Best station"
      end

      it "delegates #description to shout_get_meta" do
        expect(::Shout).to receive(:shout_get_meta).with(shout, "description").and_return("Best station")
        expect(meta.description).to eql "Best station"
      end

      it "delegates #irc= and #irc" do
        expect(::Shout).to receive(:shout_set_meta).with(shout, "irc", "#channel").and_return(0)
        meta.irc = "#channel"
        expect(::Shout).to receive(:shout_get_meta).with(shout, "irc").and_return("#channel")
        expect(meta.irc).to eql "#channel"
      end

      it "delegates #aim= and #aim" do
        expect(::Shout).to receive(:shout_set_meta).with(shout, "aim", "my_aim").and_return(0)
        meta.aim = "my_aim"
        expect(::Shout).to receive(:shout_get_meta).with(shout, "aim").and_return("my_aim")
        expect(meta.aim).to eql "my_aim"
      end

      it "delegates #icq= and #icq" do
        expect(::Shout).to receive(:shout_set_meta).with(shout, "icq", "123456").and_return(0)
        meta.icq = "123456"
        expect(::Shout).to receive(:shout_get_meta).with(shout, "icq").and_return("123456")
        expect(meta.icq).to eql "123456"
      end

      it "supports hash-like access via [] and []=" do
        expect(::Shout).to receive(:shout_set_meta).with(shout, "custom", "val").and_return(0)
        meta["custom"] = "val"

        expect(::Shout).to receive(:shout_get_meta).with(shout, "custom").and_return("val")
        expect(meta["custom"]).to eql "val"
      end
    end

    context "content_format fields" do
      subject(:content_format) { configuration.content_format }

      it "sets content format using integers" do
        expect(::Shout).to receive(:shout_set_content_format).with(shout, SHOUT_FORMAT_MP3, SHOUT_USAGE_AUDIO,
                                                                   nil).and_return(0)
        content_format.set(SHOUT_FORMAT_MP3, SHOUT_USAGE_AUDIO, nil)
      end

      it "sets content format using symbols" do
        expect(::Shout).to receive(:shout_set_content_format).with(shout, SHOUT_FORMAT_MP3, SHOUT_USAGE_AUDIO,
                                                                   nil).and_return(0)
        configuration.set_content_format(:mp3)
      end

      it "gets content format, usage, and codecs" do
        expect(::Shout).to receive(:shout_get_content_format)
          .exactly(3).times do |_shout, fmt_ptr, usage_ptr, codecs_ptr|
          fmt_ptr.write_uint(SHOUT_FORMAT_OGG)
          usage_ptr.write_uint(SHOUT_USAGE_AUDIO)
          codecs_ptr.write_pointer(::FFI::Pointer::NULL)
          0
        end

        expect(content_format.format).to eql SHOUT_FORMAT_OGG
        expect(content_format.usage).to eql SHOUT_USAGE_AUDIO
        expect(content_format.codecs).to be_nil
      end

      it "gets content format codecs when present" do
        codec_str_ptr = ::FFI::MemoryPointer.from_string("vorbis")
        expect(::Shout).to receive(:shout_get_content_format) do |_shout, fmt_ptr, usage_ptr, codecs_ptr|
          fmt_ptr.write_uint(SHOUT_FORMAT_OGG)
          usage_ptr.write_uint(SHOUT_USAGE_AUDIO)
          codecs_ptr.write_pointer(codec_str_ptr)
          0
        end

        expect(content_format.codecs).to eql "vorbis"
      end
    end
  end
end

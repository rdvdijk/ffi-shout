# frozen_string_literal: true

module Shout
  RSpec.describe FFI::Shout do
    it "initializes Shout" do
      real_ptr = ::Shout.shout_new
      expect(::Shout).to receive(:shout_new).and_return(real_ptr)
      shout = described_class.new
      expect(shout.to_ptr.address).to eql real_ptr.address
    end

    it "frees the Shout struct pointer" do
      pointer = ::FFI::Pointer.new(0x1234)
      expect(::Shout).to receive(:shout_free).with(pointer)
      described_class.release(pointer)
    end

    describe "libshout shout functions" do
      let(:shout_pointer) { ::Shout.shout_new }

      after do
        ::Shout.shout_free(shout_pointer)
      end

      context "connection parameters" do
        it "has a host" do
          expect(::Shout).to have_flag(:host).with_value("localhost").for(shout_pointer)
          expect(::Shout).to be_able_to_set(:host).to("127.0.0.1").for(shout_pointer)
        end

        it "has a port" do
          expect(::Shout).to have_flag(:port).with_value(8000).for(shout_pointer)
          expect(::Shout).to be_able_to_set(:port).to(8001).for(shout_pointer)
        end

        it "has an agent" do
          expect(::Shout).to have_getter(:agent).for(shout_pointer)
          expect(::Shout).to be_able_to_set(:agent).to("CustomAgent/1.0").for(shout_pointer)
        end

        it "has tls mode" do
          expect(::Shout).to have_flag(:tls).with_value(:auto).for(shout_pointer)
          expect(::Shout).to be_able_to_set(:tls).to(:disabled).for(shout_pointer)
        end

        it "accepts the integer constants for enum parameters" do
          expect(::Shout.shout_set_tls(shout_pointer, ::Shout::SHOUT_TLS_RFC2818)).to be 0
          expect(::Shout.shout_get_tls(shout_pointer)).to be :rfc2818
        end

        it "rejects unknown symbols for enum parameters" do
          expect do
            ::Shout.shout_set_tls(shout_pointer, :sometimes)
          end.to raise_error(ArgumentError, /invalid enum value/)
        end

        it "has ca_directory" do
          expect(::Shout).to be_able_to_set(:ca_directory).to("/etc/ssl/certs").for(shout_pointer)
          expect(::Shout.shout_get_ca_directory(shout_pointer)).to eql "/etc/ssl/certs"
        end

        it "has ca_file" do
          expect(::Shout).to be_able_to_set(:ca_file).to("/etc/ssl/cert.pem").for(shout_pointer)
          expect(::Shout.shout_get_ca_file(shout_pointer)).to eql "/etc/ssl/cert.pem"
        end

        it "has allowed_ciphers" do
          expect(::Shout).to be_able_to_set(:allowed_ciphers).to("HIGH").for(shout_pointer)
          expect(::Shout.shout_get_allowed_ciphers(shout_pointer)).to eql "HIGH"
        end

        it "has client_certificate" do
          expect(::Shout).to be_able_to_set(:client_certificate).to("/etc/ssl/client.pem").for(shout_pointer)
          expect(::Shout.shout_get_client_certificate(shout_pointer)).to eql "/etc/ssl/client.pem"
        end
      end

      context "authentication parameters" do
        it "has a user" do
          expect(::Shout).to have_flag(:user).with_value("source").for(shout_pointer)
          expect(::Shout).to be_able_to_set(:user).to("admin").for(shout_pointer)
        end

        it "has a password" do
          expect(::Shout).to be_able_to_set(:password).to("secret").for(shout_pointer)
          expect(::Shout.shout_get_password(shout_pointer)).to eql "secret"
        end
      end

      context "mount parameters" do
        it "has a mount" do
          expect(::Shout).to be_able_to_set(:mount).to("/test.mp3").for(shout_pointer)
          expect(::Shout.shout_get_mount(shout_pointer)).to eql "/test.mp3"
        end
      end

      context "other stream parameters" do
        it "has public flag" do
          expect(::Shout).to have_flag(:public).with_value(0).for(shout_pointer)
          expect(::Shout).to be_able_to_set(:public).to(1).for(shout_pointer)
        end

        it "has content language" do
          expect(::Shout).to be_able_to_set(:content_language).to("en-US").for(shout_pointer)
          expect(::Shout.shout_get_content_language(shout_pointer)).to eql "en-US"
        end

        it "has protocol" do
          expect(::Shout).to have_flag(:protocol).with_value(:http).for(shout_pointer)
          expect(::Shout).to be_able_to_set(:protocol).to(:icy).for(shout_pointer)
        end

        it "has nonblocking mode" do
          expect(::Shout).to have_flag(:nonblocking).with_value(:full).for(shout_pointer)
          expect(::Shout).to be_able_to_set(:nonblocking).to(:none).for(shout_pointer)
        end

        it "sets and gets audio info" do
          expect(::Shout.shout_set_audio_info(shout_pointer, ::Shout::SHOUT_AI_BITRATE, "128")).to be 0
          expect(::Shout.shout_get_audio_info(shout_pointer, ::Shout::SHOUT_AI_BITRATE)).to eql "128"
        end

        it "sets and gets stream meta" do
          expect(::Shout.shout_set_meta(shout_pointer, ::Shout::SHOUT_META_NAME, "My Radio")).to be 0
          expect(::Shout.shout_get_meta(shout_pointer, ::Shout::SHOUT_META_NAME)).to eql "My Radio"
        end

        it "sets and gets content format" do
          expect(::Shout.shout_set_content_format(shout_pointer, ::Shout::SHOUT_FORMAT_MP3, ::Shout::SHOUT_USAGE_AUDIO,
                                                  nil)).to be 0
          fmt_ptr = ::FFI::MemoryPointer.new(:uint)
          usage_ptr = ::FFI::MemoryPointer.new(:uint)
          codecs_ptr = ::FFI::MemoryPointer.new(:pointer)
          expect(::Shout.shout_get_content_format(shout_pointer, fmt_ptr, usage_ptr, codecs_ptr)).to be 0
          expect(fmt_ptr.read_uint).to eql ::Shout::SHOUT_FORMAT_MP3
          expect(usage_ptr.read_uint).to eql ::Shout::SHOUT_USAGE_AUDIO
        end
      end

      context "status and actions" do
        it "returns connected status" do
          expect(::Shout.shout_get_connected(shout_pointer)).to eql ::Shout::SHOUTERR_UNCONNECTED
        end

        it "returns errno" do
          expect(::Shout.shout_get_errno(shout_pointer)).to eql ::Shout::SHOUTERR_SUCCESS
        end

        it "returns error string" do
          expect(::Shout.shout_get_error(shout_pointer)).to be_a(String)
        end

        it "returns queue length when unconnected" do
          expect(::Shout.shout_queuelen(shout_pointer)).to be(-1)
        end

        it "returns delay" do
          expect(::Shout.shout_delay(shout_pointer)).to be >= 0
        end
      end

      context "obsolete methods" do
        it "sets and gets name" do
          expect(::Shout).to be_able_to_set(:name).to("Station Name").for(shout_pointer)
          expect(::Shout.shout_get_name(shout_pointer)).to eql "Station Name"
        end

        it "sets and gets url" do
          expect(::Shout).to be_able_to_set(:url).to("http://example.com").for(shout_pointer)
          expect(::Shout.shout_get_url(shout_pointer)).to eql "http://example.com"
        end

        it "sets and gets genre" do
          expect(::Shout).to be_able_to_set(:genre).to("Rock").for(shout_pointer)
          expect(::Shout.shout_get_genre(shout_pointer)).to eql "Rock"
        end

        it "sets and gets description" do
          expect(::Shout).to be_able_to_set(:description).to("Desc").for(shout_pointer)
          expect(::Shout.shout_get_description(shout_pointer)).to eql "Desc"
        end

        it "sets and gets format" do
          expect(::Shout).to have_flag(:format).with_value(:ogg).for(shout_pointer)
          expect(::Shout).to be_able_to_set(:format).to(:mp3).for(shout_pointer)
        end

        it "sets and gets dumpfile" do
          expect(::Shout).to be_able_to_set(:dumpfile).to("dump.raw").for(shout_pointer)
          expect(::Shout.shout_get_dumpfile(shout_pointer)).to eql "dump.raw"
        end
      end
    end
  end
end

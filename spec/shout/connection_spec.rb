# frozen_string_literal: true

module Shout
  RSpec.describe Connection do
    subject(:connection) { described_class.new }

    context "initialization" do
      it "initializes FFI::Shout" do
        expect(FFI::Shout).to receive(:new).and_call_original
        described_class.new
      end

      it "yields self when block is given" do
        expect do |block|
          described_class.new(&block)
        end.to yield_with_args(kind_of(described_class))
      end

      it "sets initial configuration attributes" do
        conn = described_class.new(host: "10.0.0.1", port: 8080, mount: "/live")
        expect(conn.configuration.host).to eql "10.0.0.1"
        expect(conn.configuration.port).to be 8080
        expect(conn.configuration.mount).to eql "/live"
      end
    end

    context "configuration" do
      let(:configuration) { instance_double(Configuration) }

      before do
        allow(Configuration).to receive(:new).and_return(configuration)
      end

      it "initializes a Configuration object" do
        expect(Configuration).to receive(:new).with(kind_of(FFI::Shout))
        connection.configuration
      end

      it "yields the Configuration object in #configure" do
        expect do |block|
          connection.configure(&block)
        end.to yield_with_args(configuration)
      end

      it "returns self from #configure for chaining" do
        expect(connection.configure { |config| config }).to eql connection
      end
    end

    describe "#connect and #disconnect" do
      it "calls shout_open on connect" do
        expect(::Shout).to receive(:shout_open).with(connection.shout).and_return(0)
        expect(connection.connect).to eql connection
      end

      it "raises error if shout_open fails" do
        expect(::Shout).to receive(:shout_open).with(connection.shout).and_return(SHOUTERR_NOCONNECT)
        expect do
          connection.connect
        end.to raise_error(ConnectionError)
      end

      it "supports block form for #connect with automatic disconnect" do
        expect(::Shout).to receive(:shout_open).with(connection.shout).and_return(0)
        expect(::Shout).to receive(:shout_close).with(connection.shout).and_return(0)

        yielded = nil
        connection.connect do |conn|
          yielded = conn
        end

        expect(yielded).to eql connection
      end

      it "calls shout_close on disconnect" do
        expect(::Shout).to receive(:shout_close).with(connection.shout).and_return(0)
        connection.disconnect
      end

      it "aliases open to connect and close to disconnect" do
        expect(::Shout).to receive(:shout_open).with(connection.shout).and_return(0)
        connection.open

        expect(::Shout).to receive(:shout_close).with(connection.shout).and_return(0)
        connection.close
      end
    end

    describe "#connected?" do
      it "returns true when shout_get_connected returns SHOUTERR_CONNECTED" do
        expect(::Shout).to receive(:shout_get_connected).with(connection.shout).and_return(SHOUTERR_CONNECTED)
        expect(connection.connected?).to be true
      end

      it "returns false when shout_get_connected returns SHOUTERR_UNCONNECTED" do
        expect(::Shout).to receive(:shout_get_connected).with(connection.shout).and_return(SHOUTERR_UNCONNECTED)
        expect(connection.connected?).to be false
      end
    end

    context "sending data" do
      it "sends data via shout_send" do
        data = "test audio data payload"
        expect(::Shout).to receive(:shout_send) do |shout, ptr, len|
          expect(shout).to eql connection.shout
          expect(ptr.read_string(len)).to eql data
          expect(len).to eql data.bytesize
          0
        end

        connection.send_data(data)
      end

      it "aliases send, write and << to send_data" do
        data = "audio chunk"
        expect(::Shout).to receive(:shout_send).exactly(3).times.and_return(0)

        connection.send(data)
        connection.write(data)
        connection << data
      end

      it "raises error when shout_send fails" do
        expect(::Shout).to receive(:shout_send).and_return(SHOUTERR_SOCKET)
        expect do
          connection.send_data("chunk")
        end.to raise_error(SocketError)
      end

      it "sends raw unparsed data via shout_send_raw" do
        data = "raw data"
        expect(::Shout).to receive(:shout_send_raw) do |shout, ptr, len|
          expect(shout).to eql connection.shout
          expect(ptr.read_string(len)).to eql data
          expect(len).to eql data.bytesize
          data.bytesize
        end

        expect(connection.send_raw(data)).to eql data.bytesize
      end
    end

    context "timing and pacing" do
      it "syncs stream timing via shout_sync" do
        expect(::Shout).to receive(:shout_sync).with(connection.shout)
        connection.sync
      end

      it "gets delay in milliseconds via shout_delay" do
        expect(::Shout).to receive(:shout_delay).with(connection.shout).and_return(50)
        expect(connection.delay).to be 50
      end

      it "gets queue length via shout_queuelen" do
        expect(::Shout).to receive(:shout_queuelen).with(connection.shout).and_return(1024)
        expect(connection.queuelen).to be 1024
      end
    end

    context "metadata" do
      it "raises UnconnectedError if sending metadata while not connected" do
        allow(::Shout).to receive(:shout_get_connected).and_return(SHOUTERR_UNCONNECTED)
        expect do
          connection.send_metadata("Artist - Title")
        end.to raise_error(UnconnectedError)
      end

      it "raises ArgumentError when metadata is invalid type" do
        allow(::Shout).to receive(:shout_get_connected).and_return(SHOUTERR_CONNECTED)
        expect do
          connection.send_metadata(12_345)
        end.to raise_error(ArgumentError, /Expected Metadata, Hash, or String/)
      end

      context "over the HTTP protocol (default)" do
        let(:updater) { instance_double(HttpMetadata, update: "Metadata update successful") }

        before do
          allow(::Shout).to receive(:shout_get_connected).and_return(SHOUTERR_CONNECTED)
          allow(HttpMetadata).to receive(:new).and_return(updater)
        end

        it "uses the HTTP protocol by default" do
          expect(connection.http_protocol?).to be true
        end

        it "sends metadata through HttpMetadata instead of libshout" do
          expect(::Shout).not_to receive(:shout_set_metadata_utf8)
          expect(HttpMetadata).to receive(:new)
            .with(connection.configuration, timeout: HttpMetadata::DEFAULT_TIMEOUT)
          expect(updater).to receive(:update) do |metadata|
            expect(metadata["song"]).to eql "Daft Punk - One More Time"
          end

          meta = connection.send_metadata("Daft Punk - One More Time")
          expect(meta["song"]).to eql "Daft Punk - One More Time"
        end

        it "passes a custom metadata_timeout" do
          connection.metadata_timeout = 1.5
          expect(HttpMetadata).to receive(:new).with(connection.configuration, timeout: 1.5)
          connection.send_metadata("Track")
        end

        it "sends metadata from a Hash" do
          meta = connection.send_metadata(song: "Kraftwerk - The Robots")
          expect(meta["song"]).to eql "Kraftwerk - The Robots"
        end

        it "returns a given Metadata instance" do
          metadata = Metadata.new(song: "Air - Sexy Boy")
          expect(updater).to receive(:update).with(metadata)
          expect(connection.send_metadata(metadata)).to eql metadata
        end

        it "aliases update_metadata and metadata= to send_metadata" do
          expect(updater).to receive(:update).twice
          connection.update_metadata("Track 1")
          connection.metadata = "Track 2"
        end

        it "propagates errors from HttpMetadata" do
          allow(updater).to receive(:update).and_raise(LoginError, "rejected")
          expect { connection.send_metadata("Track") }.to raise_error(LoginError, "rejected")
        end
      end

      context "over other protocols" do
        before do
          connection.configuration.protocol = :icy
          allow(::Shout).to receive(:shout_get_connected).and_return(SHOUTERR_CONNECTED)
        end

        it "is not the HTTP protocol" do
          expect(connection.http_protocol?).to be false
        end

        it "sends metadata via shout_set_metadata_utf8" do
          expect(HttpMetadata).not_to receive(:new)
          expect(::Shout).to receive(:shout_set_metadata_utf8) do |shout, meta_ptr|
            expect(shout).to eql connection.shout
            expect(meta_ptr).to respond_to(:to_ptr)
            0
          end

          meta = connection.send_metadata("Daft Punk - One More Time")
          expect(meta["song"]).to eql "Daft Punk - One More Time"
        end

        it "raises when shout_set_metadata_utf8 fails" do
          expect(::Shout).to receive(:shout_set_metadata_utf8).and_return(SHOUTERR_METADATA)
          expect { connection.send_metadata("Track") }.to raise_error(MetadataError)
        end
      end
    end

    context "error reporting" do
      it "returns the error string via #error" do
        expect(::Shout).to receive(:shout_get_error).with(connection.shout).and_return("No error")
        expect(connection.error).to eql "No error"
      end

      it "returns the error number via #errno" do
        expect(::Shout).to receive(:shout_get_errno).with(connection.shout).and_return(0)
        expect(connection.errno).to be 0
      end
    end

    context "Class level methods and aliases" do
      it "provides Connection.open class method" do
        conn = instance_double(described_class)
        expect(described_class).to receive(:new).and_return(conn)
        expect(conn).to receive(:connect)
        described_class.open
      end

      it "provides Connection.open class method with a block" do
        conn = instance_double(described_class)
        expect(described_class).to receive(:new).and_return(conn)
        expect(conn).to receive(:connect).and_yield(conn)
        yielded = nil
        described_class.open { |c| yielded = c }
        expect(yielded).to eql conn
      end

      it "aliases Shout::Client to Shout::Connection" do
        expect(::Shout::Client).to eql ::Shout::Connection
      end

      it "allows Shout.new to create a Connection" do
        expect(::Shout.new).to be_a(described_class)
      end
    end
  end
end

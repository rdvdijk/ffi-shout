# frozen_string_literal: true

module Shout
  RSpec.describe HttpMetadata do
    let(:success_body) do
      '<?xml version="1.0"?><iceresponse><message>Metadata update successful</message><return>1</return></iceresponse>'
    end
    let(:server) { FakeHttpServer.new(body: success_body) }
    let(:port) { server.port }
    let(:connection) do
      Connection.new(host: "127.0.0.1", port: port, mount: "/live stream.mp3",
                     user: "source", password: "s3cr3t&")
    end
    let(:configuration) { connection.configuration }
    let(:metadata) { Metadata.new(song: "Daft Punk - One More Time") }

    subject(:updater) { described_class.new(configuration, timeout: 1) }

    after { server.stop }

    def last_request
      server.requests.pop(timeout: 2) or raise "no request received"
    end

    context "on success" do
      it "returns the server message" do
        expect(updater.update(metadata)).to eql "Metadata update successful"
      end

      it "sends a GET to /admin/metadata with escaped mount and metadata" do
        updater.update(Metadata.new(song: "Sigur Rós & Co + friends"))
        request = last_request
        expect(request.request_line).to start_with "GET "
        expect(request.path).to eql "/admin/metadata?mode=updinfo&charset=UTF-8" \
                                    "&mount=%2Flive%20stream.mp3" \
                                    "&song=Sigur%20R%C3%B3s%20%26%20Co%20%2B%20friends"
      end

      it "sends the credentials with the first request" do
        updater.update(metadata)
        expected = "Basic #{["source:s3cr3t&"].pack("m0")}"
        expect(last_request.headers["authorization"]).to eql expected
        expect(server.requests).to be_empty
      end

      it "sends the configured user agent" do
        configuration.agent = "my-radio/1.0"
        updater.update(metadata)
        expect(last_request.headers["user-agent"]).to eql "my-radio/1.0"
      end

      it "leaves the default user agent when none is configured" do
        allow(configuration).to receive(:agent).and_return(nil)
        updater.update(metadata)
        expect(last_request.headers["user-agent"]).to eql "Ruby"
      end
    end

    context "on server errors" do
      it "raises LoginError on 401" do
        server = FakeHttpServer.new(status: "401 Authentication Required")
        configuration.port = server.port
        expect { updater.update(metadata) }.to raise_error(LoginError, /rejected \(HTTP 401\)/)
        server.stop
      end

      it "raises LoginError on 403" do
        server = FakeHttpServer.new(status: "403 Forbidden")
        configuration.port = server.port
        expect { updater.update(metadata) }.to raise_error(LoginError, /HTTP 403/)
        server.stop
      end

      it "raises MetadataError with the server message on other errors" do
        body = "<iceresponse><message>Source does not exist</message><return>0</return></iceresponse>"
        server = FakeHttpServer.new(status: "400 Bad Request", body: body)
        configuration.port = server.port
        expect { updater.update(metadata) }
          .to raise_error(MetadataError, "Metadata update failed (HTTP 400: Source does not exist)")
        server.stop
      end

      it "raises MetadataError when a 200 response does not report success" do
        server = FakeHttpServer.new(body: "<iceresponse><message>Nope</message><return>0</return></iceresponse>")
        configuration.port = server.port
        expect { updater.update(metadata) }.to raise_error(MetadataError, /HTTP 200: Nope/)
        server.stop
      end
    end

    context "on network errors" do
      it "raises ConnectionError when writing the request times out" do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Net::WriteTimeout) # rubocop:disable RSpec/AnyInstance
        expect { updater.update(metadata) }.to raise_error(ConnectionError, /WriteTimeout/)
      end

      it "raises ConnectionError when the server is unreachable" do
        configuration.port = FakeHttpServer.closed_port
        expect { updater.update(metadata) }.to raise_error(ConnectionError, /ECONNREFUSED/)
      end

      it "raises ConnectionError when the server does not answer in time" do
        server = FakeHttpServer.new(respond: false)
        configuration.port = server.port
        updater = described_class.new(configuration, timeout: 0.2)
        expect { updater.update(metadata) }.to raise_error(ConnectionError, /ReadTimeout/)
        server.stop
      end
    end

    context "TLS modes" do
      %i[disabled auto].each do |mode|
        it "uses plain HTTP for tls = #{mode.inspect}" do
          configuration.tls = mode
          expect(updater.update(metadata)).to eql "Metadata update successful"
        end
      end

      it "uses HTTPS with peer verification for tls = :rfc2818" do
        configuration.tls = :rfc2818
        configuration.ca_file = "/tmp/ca.pem"
        configuration.ca_directory = "/tmp/certs"

        http = nil
        allow(Net::HTTP).to receive(:new).and_wrap_original do |original, *args|
          http = original.call(*args)
        end

        # The fake server only speaks plain HTTP, so the TLS handshake fails.
        expect { updater.update(metadata) }.to raise_error(ConnectionError, /SSL|EOF|ECONNRESET/)
        expect(http.use_ssl?).to be true
        expect(http.verify_mode).to eql OpenSSL::SSL::VERIFY_PEER
        expect(http.ca_file).to eql "/tmp/ca.pem"
        expect(http.ca_path).to eql "/tmp/certs"
      end

      it "does not set CA locations for tls = :rfc2818 when none are configured" do
        configuration.tls = :rfc2818
        allow(configuration).to receive_messages(ca_file: nil, ca_directory: nil)

        http = nil
        allow(Net::HTTP).to receive(:new).and_wrap_original do |original, *args|
          http = original.call(*args)
        end

        expect { updater.update(metadata) }.to raise_error(ConnectionError)
        expect(http.ca_file).to be_nil
        expect(http.ca_path).to be_nil
      end

      %i[auto_no_plain rfc2817].each do |mode|
        it "raises UnsupportedError for tls = #{mode.inspect}" do
          configuration.tls = mode
          expect { updater.update(metadata) }.to raise_error(UnsupportedError, /not supported/)
          expect(server.requests).to be_empty
        end
      end
    end

    it "defaults to a 5 second timeout" do
      expect(described_class.new(configuration).timeout).to be 5
    end
  end
end

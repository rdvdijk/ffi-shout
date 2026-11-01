# frozen_string_literal: true

require_relative "../lib/icecast_settings"

# Needs a local Icecast server (localhost:8000 by default, see
# IcecastSettings) with a mount point /stream.mp3 configured; see "Running
# the integration specs" in the README.
RSpec.describe "Connection Integration", :integration do
  context "connecting to Icecast 2 server" do
    let(:connection) do
      Shout::Connection.new do |c|
        c.configuration.host = IcecastSettings::HOST
        c.configuration.port = IcecastSettings::PORT
        c.configuration.mount = IcecastSettings::MOUNT
        c.configuration.user = IcecastSettings::SOURCE_USER
        c.configuration.password = "invalid_password"
        c.configuration.protocol = :http
        c.configuration.set_content_format(:mp3)
      end
    end

    it "attempts connection to Icecast 2 server and reports authentication failure" do
      expect do
        connection.connect
      end.to raise_error(Shout::LoginError, /Login failed/)
    end

    it "reports unconnected status after failed connection attempt" do
      expect { connection.connect }.to raise_error(Shout::LoginError)
      expect(connection.connected?).to be false
    end
  end

  context "connecting to unreachable server" do
    let(:connection) do
      Shout::Connection.new do |c|
        c.configuration.host = "127.0.0.1"
        c.configuration.port = 59_999
        c.configuration.mount = "/stream.mp3"
        c.configuration.password = "secret"
      end
    end

    it "raises ConnectionError when host/port is unreachable" do
      expect do
        connection.connect
      end.to raise_error(Shout::ConnectionError)
    end
  end

  context "sending metadata" do
    let(:connection) { Shout::Connection.new }

    it "refuses to send metadata when not connected" do
      expect do
        connection.send_metadata("Artist - Title")
      end.to raise_error(Shout::UnconnectedError)
    end

    it "refuses to send metadata via metadata= when not connected" do
      expect do
        connection.metadata = { song: "Artist - Title" }
      end.to raise_error(Shout::UnconnectedError)
    end
  end
end

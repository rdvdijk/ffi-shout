require 'spec_helper'

describe "Connection Integration", :integration => true do

  context "connecting to Icecast 2 server" do
    let(:connection) do
      Shout::Connection.new do |c|
        c.configuration.host = "127.0.0.1"
        c.configuration.port = 9000
        c.configuration.mount = "/stream.mp3"
        c.configuration.user = "source"
        c.configuration.password = "invalid_password"
        c.configuration.protocol = :http
        c.configuration.format = :mp3
      end
    end

    it "attempts connection to Icecast 2 server and reports authentication failure" do
      expect {
        connection.connect
      }.to raise_error(Shout::LoginError, /Login failed/)
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
        c.configuration.port = 59999
        c.configuration.mount = "/stream.mp3"
        c.configuration.password = "secret"
      end
    end

    it "raises ConnectionError when host/port is unreachable" do
      expect {
        connection.connect
      }.to raise_error(Shout::ConnectionError)
    end
  end

  context "sending metadata" do
    let(:connection) { Shout::Connection.new }

    it "refuses to send metadata when not connected" do
      expect {
        connection.send_metadata("Artist - Title")
      }.to raise_error(Shout::UnconnectedError)
    end

    it "refuses to send metadata via metadata= when not connected" do
      expect {
        connection.metadata = { song: "Artist - Title" }
      }.to raise_error(Shout::UnconnectedError)
    end
  end

end

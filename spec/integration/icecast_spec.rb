require 'spec_helper'
require 'net/http'
require 'json'
require 'securerandom'

# Talks to a real Icecast server on localhost:9000 and checks the effects
# through its public /status-json.xsl page.
#
# Each connection runs in a forked child process. libshout calls block inside
# C while holding the GVL, so a Ruby Timeout can't interrupt them. A child
# process can always be killed, so a stuck call fails the test instead of
# hanging the whole suite.
describe "Icecast server integration", :integration => true do

  ICECAST_HOST       = "localhost"
  ICECAST_PORT       = 9000
  ICECAST_MOUNT      = "/stream.mp3"
  ICECAST_STATUS_URI = URI("http://#{ICECAST_HOST}:#{ICECAST_PORT}/status-json.xsl")
  ICECAST_TIMEOUT    = 10

  # One MPEG-1 Layer III frame (128 kbps, 44.1 kHz, stereo, 417 bytes). The
  # all-zero payload decodes as silence. Icecast only publishes a mount's
  # title once audio is actually flowing, so the source streams these.
  SILENT_MP3_FRAME = ([0xFF, 0xFB, 0x90, 0x64].pack("C*") + ("\0" * 413)).b

  def build_connection
    Shout::Connection.new do |c|
      c.configuration.host = ICECAST_HOST
      c.configuration.port = ICECAST_PORT
      c.configuration.mount = ICECAST_MOUNT
      c.configuration.user = "source"
      c.configuration.password = "changeme"
      c.configuration.protocol = :http
      c.configuration.format = :mp3
    end
  end

  # Returns the status entry for our mount, or nil if no source is on it.
  def mount_status
    response = Net::HTTP.start(ICECAST_STATUS_URI.host, ICECAST_STATUS_URI.port,
                               open_timeout: 2, read_timeout: 2) do |http|
      http.get(ICECAST_STATUS_URI.request_uri)
    end
    expect(response.code).to eq("200"), "GET #{ICECAST_STATUS_URI} returned #{response.code}"

    sources = JSON.parse(response.body).dig("icestats", "source")
    Array(sources.is_a?(Hash) ? [sources] : sources).find do |source|
      source["listenurl"].to_s.end_with?(ICECAST_MOUNT)
    end
  end

  def wait_for(description, timeout: ICECAST_TIMEOUT)
    deadline = Time.now + timeout
    loop do
      result = yield
      return result if result
      raise "Timed out after #{timeout}s waiting for #{description}" if Time.now > deadline
      sleep 0.25
    end
  end

  # Forks a child that connects, starts streaming silence, runs the block,
  # prints "done" to a pipe and keeps streaming until it is killed. Waits for "done" (or
  # an error message) and returns the child's pid.
  def start_source
    reader, writer = IO.pipe
    pid = fork do
      reader.close
      begin
        connection = build_connection
        connection.connect
        stream = -> { connection.send_data(SILENT_MP3_FRAME * 10); connection.sync }
        stream.call
        yield connection
        writer.puts "done"
        writer.flush
        loop { stream.call }
      rescue Exception => e
        writer.puts "error: #{e.class}: #{e.message}"
        writer.flush
      ensure
        exit!(0) # skip at_exit hooks (SimpleCov) in the child
      end
    end
    writer.close
    @child_pids << pid

    ready = IO.select([reader], nil, nil, ICECAST_TIMEOUT)
    raise "Source process did not report back within #{ICECAST_TIMEOUT}s (blocked in libshout?)" unless ready
    message = reader.gets.to_s.strip
    raise "Source process failed: #{message}" unless message == "done"
    pid
  ensure
    reader&.close
  end

  def stop_source(pid)
    Process.kill(:KILL, pid)
    Process.wait(pid)
  rescue Errno::ESRCH, Errno::ECHILD
    nil
  ensure
    @child_pids.delete(pid)
  end

  before do
    @child_pids = []
    # A source killed by a previous example can linger briefly on the server.
    wait_for("#{ICECAST_MOUNT} to be free before the test") { mount_status.nil? }
  end

  after do
    @child_pids.dup.each { |pid| stop_source(pid) }
  end

  it "connects as a source and shows up on the mount" do
    pid = start_source do |conn|
      raise "connected? returned false" unless conn.connected?
    end

    status = wait_for("#{ICECAST_MOUNT} to appear in #{ICECAST_STATUS_URI}") { mount_status }
    expect(status["listenurl"]).to end_with(ICECAST_MOUNT)

    stop_source(pid)
    wait_for("#{ICECAST_MOUNT} to disappear after disconnect") { mount_status.nil? }
  end

  it "sends metadata that is visible on the mount" do
    title = "Integration Artist - Song #{SecureRandom.hex(4)}"

    start_source do |conn|
      conn.send_metadata(song: title)
    end

    status = wait_for("title #{title.inspect} on #{ICECAST_MOUNT}") do
      s = mount_status
      s if s && s["title"] == title
    end
    expect(status["title"]).to eq(title)
  end

end

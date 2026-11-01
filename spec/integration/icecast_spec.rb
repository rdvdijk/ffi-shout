# frozen_string_literal: true

require "net/http"
require "json"
require "securerandom"
require_relative "../lib/icecast_settings"

# Helpers for talking to a real Icecast server and checking the effects
# through its public /status-json.xsl page. The server (localhost:8000 with
# source password hackme by default, see IcecastSettings) needs a mount point
# /stream.mp3 configured in icecast.xml. See "Running the integration specs"
# in the README.
#
# Each connection runs in a forked child process. libshout calls block inside
# C, so a Ruby Timeout can't interrupt them. A child process can always be
# killed, so a stuck call fails the test instead of hanging the whole suite.
module IcecastIntegration
  HOST       = IcecastSettings::HOST
  PORT       = IcecastSettings::PORT
  MOUNT      = IcecastSettings::MOUNT
  STATUS_URI = URI("http://#{HOST}:#{PORT}/status-json.xsl")
  TIMEOUT    = 10

  # One MPEG-1 Layer III frame (128 kbps, 44.1 kHz, stereo, 417 bytes). The
  # all-zero payload decodes as silence. Icecast only publishes a mount's
  # title once audio is actually flowing, so the source streams these.
  SILENT_MP3_FRAME = ([0xFF, 0xFB, 0x90, 0x64].pack("C*") + ("\0" * 413)).b

  def build_connection
    Shout::Connection.new do |c|
      c.configuration.host = HOST
      c.configuration.port = PORT
      c.configuration.mount = MOUNT
      c.configuration.user = IcecastSettings::SOURCE_USER
      c.configuration.password = IcecastSettings::SOURCE_PASSWORD
      c.configuration.protocol = :http
      c.configuration.set_content_format(:mp3)
    end
  end

  # Returns the status entry for our mount, or nil if no source is on it.
  def mount_status
    sources = fetch_status.dig("icestats", "source")
    Array(sources.is_a?(Hash) ? [sources] : sources).find do |source|
      source["listenurl"].to_s.end_with?(MOUNT)
    end
  end

  def fetch_status
    response = Net::HTTP.start(STATUS_URI.host, STATUS_URI.port, open_timeout: 2, read_timeout: 2) do |http|
      http.get(STATUS_URI.request_uri)
    end
    expect(response.code).to eq("200"), "GET #{STATUS_URI} returned #{response.code}"
    JSON.parse(response.body)
  end

  def wait_for(description, timeout: TIMEOUT)
    deadline = Time.now + timeout
    loop do
      result = yield
      return result if result
      raise "Timed out after #{timeout}s waiting for #{description}" if Time.now > deadline

      sleep 0.25
    end
  end

  # Forks a child that connects, starts streaming silence, runs the block,
  # reports "done" through a pipe and keeps streaming until it is killed.
  # Waits for "done" (or an error message) and returns the child's pid.
  def start_source(&)
    reader, writer = IO.pipe
    pid = fork do
      reader.close
      run_source(writer, &)
    end
    writer.close
    child_pids << pid

    ready = reader.wait_readable(TIMEOUT)
    raise "Source process did not report back within #{TIMEOUT}s (blocked in libshout?)" unless ready

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
    child_pids.delete(pid)
  end

  private

  # Runs in the forked child.
  def run_source(writer)
    connection = build_connection
    connection.connect
    stream = -> { connection.send_data(SILENT_MP3_FRAME * 10) && connection.sync }
    stream.call
    yield connection
    report(writer, "done")
    loop { stream.call }
  rescue StandardError => e
    report(writer, "error: #{e.class}: #{e.message}")
  ensure
    exit!(0) # skip at_exit hooks (SimpleCov) in the child
  end

  def report(writer, message)
    writer.puts message
    writer.flush
  end
end

RSpec.describe "Icecast server integration", :integration do
  include IcecastIntegration

  let(:child_pids) { [] }

  before do
    # A source killed by a previous example can linger briefly on the server.
    wait_for("#{IcecastIntegration::MOUNT} to be free before the test") { mount_status.nil? }
  end

  after do
    child_pids.dup.each { |pid| stop_source(pid) }
  end

  it "connects as a source and shows up on the mount" do
    pid = start_source do |conn|
      raise "connected? returned false" unless conn.connected?
    end

    status = wait_for("#{IcecastIntegration::MOUNT} to appear in #{IcecastIntegration::STATUS_URI}") { mount_status }
    expect(status["listenurl"]).to end_with(IcecastIntegration::MOUNT)

    stop_source(pid)
    wait_for("#{IcecastIntegration::MOUNT} to disappear after disconnect") { mount_status.nil? }
  end

  it "sends metadata that is visible on the mount" do
    title = "Integration Artist - Song #{SecureRandom.hex(4)}"

    start_source do |conn|
      conn.send_metadata(song: title)
    end

    status = wait_for("title #{title.inspect} on #{IcecastIntegration::MOUNT}") do
      s = mount_status
      s if s && s["title"] == title
    end
    expect(status["title"]).to eq(title)
  end
end

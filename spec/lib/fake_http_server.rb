require 'socket'

# A tiny HTTP server on a random local port that records each request and
# answers with a canned response. With `respond: false` it accepts
# connections but never answers, to exercise read timeouts.
class FakeHttpServer
  Request = Struct.new(:request_line, :headers) do
    def path
      request_line.split(" ")[1]
    end
  end

  attr_reader :requests, :port

  def initialize(status: "200 OK", body: "", respond: true)
    @status = status
    @body = body
    @respond = respond
    @requests = Queue.new
    @server = TCPServer.new("127.0.0.1", 0)
    @port = @server.addr[1]
    @clients = []
    @thread = Thread.new { serve }
  end

  def stop
    @server.close
    @thread.join
    @clients.each(&:close)
  end

  def self.closed_port
    server = TCPServer.new("127.0.0.1", 0)
    server.addr[1].tap { server.close }
  end

  private

  def serve
    loop do
      client = @server.accept
      @clients << client
      handle(client)
    end
  rescue IOError, Errno::EBADF
    nil # server socket closed by #stop
  end

  def handle(client)
    request_line = client.gets.to_s.chomp
    headers = {}
    while (line = client.gets) && line != "\r\n"
      name, value = line.chomp.split(": ", 2)
      headers[name.downcase] = value
    end
    @requests << Request.new(request_line, headers)
    return unless @respond

    client.write "HTTP/1.1 #{@status}\r\nContent-Type: text/xml\r\n" \
                 "Content-Length: #{@body.bytesize}\r\nConnection: close\r\n\r\n#{@body}"
    client.close
  end
end

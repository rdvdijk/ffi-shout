# frozen_string_literal: true

# Where the integration specs find the local Icecast server. The defaults are
# Icecast's own; override them with environment variables to use a server
# that is set up differently, e.g.
#
#   ICECAST_PORT=9000 ICECAST_SOURCE_PASSWORD=secret bundle exec rake spec:integration
#
# The server also needs a mount point /stream.mp3 configured in icecast.xml.
module IcecastSettings
  HOST            = ENV.fetch("ICECAST_HOST", "localhost")
  PORT            = Integer(ENV.fetch("ICECAST_PORT", "8000"))
  SOURCE_USER     = "source"
  SOURCE_PASSWORD = ENV.fetch("ICECAST_SOURCE_PASSWORD", "hackme")
  MOUNT           = "/stream.mp3"
end

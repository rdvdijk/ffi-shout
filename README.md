# Shout (shout-ruby-ffi)

Ruby FFI bindings for [libshout](https://icecast.org/), the streaming library for Icecast.

## Installation

### Prerequisites

Ensure you have the libshout development library installed on your system:

- Ubuntu / Debian: `sudo apt-get install libshout3-dev`
- Arch Linux: `sudo pacman -S libshout`
- macOS (Homebrew): `brew install libshout`

### Gem Installation

Add to your Gemfile:

```ruby
gem 'shout-ruby-ffi'
```

And run:

```bash
bundle install
```

## Usage

### Connecting and Streaming to Icecast

#### 1. Automatic Lifecycle (Block Form)

You can pass a block to `connect`, which automatically handles disconnecting when the block completes (even if an exception is raised):

```ruby
require 'shout'

connection = Shout::Connection.new do |conn|
  conn.configuration.host = "127.0.0.1"
  conn.configuration.port = 8000
  conn.configuration.mount = "/stream.mp3"
  conn.configuration.user = "source"
  conn.configuration.password = "hackme"
  conn.configuration.protocol = :http
  conn.configuration.set_content_format(:mp3)

  # Audio information
  conn.configuration.audio_info.bitrate = 128
  conn.configuration.audio_info.samplerate = 44100
  conn.configuration.audio_info.channels = 2

  # Stream metadata
  conn.configuration.meta.name = "My Radio Station"
  conn.configuration.meta.genre = "Rock"
  conn.configuration.meta.description = "Awesome Radio Stream"
  conn.configuration.meta.url = "https://example.com"
end

# Connect to Icecast with automatic disconnect
connection.connect do |conn|
  # Update song metadata
  conn.update_metadata(song: "Queen - Bohemian Rhapsody")

  # Stream audio chunks
  File.open("audio.mp3", "rb") do |file|
    while chunk = file.read(4096)
      conn.send_data(chunk)

      # Wait for the server timing synchronization
      conn.sync
    end
  end
end
# Automatically disconnected once the block exits
```

#### 2. Manual Lifecycle (Holding the Connection in a Field)

If you need a long-running stream managed across multiple methods or worker events, call `connect` without a block. This returns the connection instance, allowing you to store it in an instance variable (field) and explicitly call `disconnect` (or `close`) later:

```ruby
require 'shout'

class RadioBroadcaster
  attr_reader :connection

  def initialize
    @connection = Shout::Connection.new do |conn|
      conn.configuration.host = "127.0.0.1"
      conn.configuration.port = 8000
      conn.configuration.mount = "/stream.mp3"
      conn.configuration.user = "source"
      conn.configuration.password = "hackme"
      conn.configuration.protocol = :http
      conn.configuration.set_content_format(:mp3)
    end
  end

  def start
    # Connects and keeps the socket open
    @connection.connect
  end

  def broadcast(chunk)
    @connection.send_data(chunk)
    @connection.sync
  end

  def change_track(title)
    @connection.update_metadata(song: title)
  end

  def stop
    # Manually close the connection when done
    @connection.disconnect if @connection.connected?
  end
end

# Example usage:
broadcaster = RadioBroadcaster.new
broadcaster.start

broadcaster.change_track("Led Zeppelin - Immigrant Song")
broadcaster.broadcast(audio_data)

# ... later in your application lifecycle:
broadcaster.stop
```

### Sending Metadata

You can update stream metadata dynamically at any time while connected:

```ruby
# Using a String (defaults to "song" metadata)
connection.metadata = "Artist - Song Title"

# Using a Hash
connection.update_metadata(song: "Artist - Song Title")

# Using a Shout::Metadata object
metadata = Shout::Metadata.new
metadata.add("song", "Artist - Song Title")
connection.send_metadata(metadata)
```

With the HTTP protocol (the default), metadata updates don't go through libshout's `shout_set_metadata_utf8`. With Icecast 2.5, libshout 2.4.6 never returns from that call ([icecast-libshout#2341](https://gitlab.xiph.org/xiph/icecast-libshout/-/issues/2341)). Instead, this gem sends the request to Icecast's `/admin/metadata` endpoint itself, with the source credentials included in the first request. Other protocols still use libshout.

- Requests time out after 5 seconds. Change this with `connection.metadata_timeout = 2`.
- Failures raise `Shout::LoginError` (credentials rejected), `Shout::MetadataError` (the server refused the update) or `Shout::ConnectionError` (network error or timeout).
- For TLS, set `tls` to `:rfc2818` (HTTPS) or `:disabled`/`:auto` (plain HTTP). `:auto_no_plain` and `:rfc2817` raise `Shout::UnsupportedError` for metadata updates.

### Configuration Options

The configuration object exposes all properties supported by `shout.h`:

```ruby
connection.configure do |config|
  # Server parameters
  config.host = "localhost"
  config.port = 8000
  config.mount = "/mountpoint"
  config.user = "source"
  config.password = "secret"
  config.agent = "CustomAgent/1.0"

  # Protocol & Format
  config.protocol = :http       # :http, :xaudiocast, :icy, :roaraudio
  config.set_content_format(:mp3) # :mp3, :ogg, :webm, :matroska, :text

  # TLS options
  config.tls = :auto            # :disabled, :auto, :auto_no_plain, :rfc2818, :rfc2817
  config.ca_directory = "/etc/ssl/certs"
  config.ca_file = "/etc/ssl/cert.pem"

  # Streaming options
  config.public = false
  config.nonblocking = :full    # :full (blocking), :none (non-blocking), :default
  config.content_language = "en-US"

  # Audio info
  config.audio_info.bitrate = 320
  config.audio_info.samplerate = 44100
  config.audio_info.channels = 2
  config.audio_info.quality = 5

  # Station meta
  config.meta.name = "My Station"
  config.meta.url = "http://myradio.fm"
  config.meta.genre = "Electronic"
  config.meta.description = "24/7 Electronic Music"
end
```

Settings that take a symbol also read back as one: `config.protocol` returns `:http`, `config.tls` returns `:auto`, and `config.content_format.format` returns `:mp3`. Setting an unknown symbol raises `ArgumentError`.

`config.format=`, `config.name=`, `config.url=`, `config.genre=`, `config.description=` and `config.dumpfile=` call libshout functions that libshout marks obsolete. They still work, but print a deprecation warning when Ruby's deprecation warnings are on (`ruby -W:deprecated`). Use `set_content_format` and `config.meta.*` instead.

## Development

Make sure you are using Ruby 3.4.12, then install the dependencies:

```bash
chruby 3.4.12
bundle install
```

| Command | What it does |
|---|---|
| `bundle exec rake` | Runs the unit specs and RuboCop |
| `bundle exec rspec` | Runs the unit specs only |
| `bundle exec rake spec:integration` | Runs the integration specs (see below) |
| `bundle exec rubocop` | Lints the code (`-a` fixes what it safely can) |
| `COVERAGE=1 bundle exec rspec` | Also writes a coverage report to `coverage/lcov.info` |

The integration specs (`spec/integration`) need a local Icecast server on `localhost:9000` with source password `changeme`. They check their results through `/status-json.xsl`. They are skipped by default; `bundle exec rspec --tag integration` runs them as well.

## License

MIT License. See [LICENSE.txt](LICENSE.txt).

# ffi-shout

Ruby FFI bindings for [libshout](https://icecast.org/), the streaming library for Icecast.

See [CHANGELOG.md](CHANGELOG.md) for what changed.

## Installation

### Requirements

- Ruby 3.2 or newer
- libshout 2.4.6 or newer, including its development files:
  - Ubuntu / Debian: `sudo apt-get install libshout3-dev`
  - Arch Linux: `sudo pacman -S libshout`
  - macOS (Homebrew): `brew install libshout`

Older distributions may ship an older libshout; check with `pkg-config --modversion shout`. With libshout older than 2.4.6, `require "shout"` raises a `LoadError` that names the version it found.

### Gem Installation

Add to your Gemfile:

```ruby
gem "ffi-shout"
```

And run:

```bash
bundle install
```

Then load it with `require "shout"` (or `require "ffi-shout"`; Bundler's auto-require uses that one). The library lives in the `Shout` module.

The older, unmaintained [ruby-shout](https://rubygems.org/gems/ruby-shout) gem (a C extension) also installs `shout.rb` and defines a top-level `Shout` class, so the two gems can't be used together.

## Usage

### Connecting and Streaming to Icecast

#### 1. Automatic Lifecycle (Block Form)

You can pass a block to `connect`, which automatically handles disconnecting when the block completes (even if an exception is raised). `connect` returns the block's value.

```ruby
require "shout"

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
    while (chunk = file.read(4096))
      conn.send_data(chunk)

      # Wait for the server timing synchronization
      conn.sync
    end
  end
end
# Automatically disconnected once the block exits
```

Configuration attributes can also be passed as keyword arguments, and `Connection.open` creates and connects in one step:

```ruby
Shout::Connection.open(host: "127.0.0.1", port: 8000, mount: "/stream.mp3",
                       user: "source", password: "hackme") do |conn|
  conn.update_metadata(song: "Daft Punk - One More Time")
  # ...
end
```

An unknown attribute raises `ArgumentError` (for example `unknown attribute(s): hots`). Settings without a keyword form, such as `set_content_format` or `audio_info`, go in a block as above.

#### 2. Manual Lifecycle (Holding the Connection in a Field)

If you need a long-running stream managed across multiple methods or worker events, call `connect` without a block. This returns the connection instance, allowing you to store it in an instance variable (field) and explicitly call `disconnect` (or `close`) later:

```ruby
require "shout"

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
    @connection.send_data(chunk).sync
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
broadcaster.broadcast(audio_data) # audio_data: a chunk of MP3 data, e.g. from File#read

# ... later in your application lifecycle:
broadcaster.stop
```

`send_data` (and its aliases `write` and `<<`), `sync` and `disconnect` return the connection, so calls can be chained: `connection << chunk1 << chunk2`.

#### Blocking and threads

libshout calls that wait on the network (`connect`, `send_data`, `sync`, `disconnect`) block the calling thread but let other Ruby threads keep running.

Non-blocking mode (`nonblocking = :none`) is not supported yet: in that mode libshout reports a busy connection, which this gem raises as `Shout::BusyError` instead of retrying.

### Sending Metadata

You can update stream metadata dynamically at any time while connected:

```ruby
# Using a String (defaults to "song" metadata)
connection.metadata = "Artist - Song Title"

# Using a Hash
connection.update_metadata(song: "Artist - Song Title")

# Using a Shout::Metadata object
metadata = Shout::Metadata.new(song: "Artist - Song Title")
connection.send_metadata(metadata)
```

`Shout::Metadata` behaves like a small hash of strings: `metadata["song"]` reads a value, `metadata.add("artist", "Queen")` (or `metadata["artist"] = "Queen"`) adds one, it is `Enumerable` (`each` yields key and value), and two instances with the same keys and values are equal.

With the HTTP protocol (the default), metadata updates don't go through libshout's `shout_set_metadata_utf8`. With Icecast 2.5, libshout 2.4.6 never returns from that call ([icecast-libshout#2341](https://gitlab.xiph.org/xiph/icecast-libshout/-/issues/2341)). Instead, this gem sends the request to Icecast's `/admin/metadata` endpoint itself, with the source credentials included in the first request. Other protocols still use libshout.

- Requests time out after 5 seconds. Change this with `connection.metadata_timeout = 2`.
- Failures raise `Shout::LoginError` (credentials rejected), `Shout::MetadataError` (the server refused the update) or `Shout::ConnectionError` (network error or timeout).
- For TLS, set `tls` to `:rfc2818` (HTTPS) or `:disabled`/`:auto` (plain HTTP). `:auto_no_plain` and `:rfc2817` raise `Shout::UnsupportedError` for metadata updates.

> **Security note:** with `tls = :auto` (libshout's default), libshout may upgrade the audio connection to TLS, but metadata updates are sent over plain HTTP, so the source password is sent unencrypted. If you rely on TLS, set `tls = :rfc2818`.

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
  config.nonblocking = :full    # :full (blocking); :none is not supported yet, see above
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

Settings that take a symbol also read back as one: `config.protocol` returns `:http`, `config.tls` returns `:auto`, and `config.content_format.format` returns `:mp3`. Setting an unknown symbol raises `ArgumentError`. The on/off flags also have a `?` reader: `config.public?` and `config.nonblocking?`.

`config.format=`, `config.name=`, `config.url=`, `config.genre=`, `config.description=` and `config.dumpfile=` call libshout functions that libshout marks obsolete. They still work, but print a deprecation warning when Ruby's deprecation warnings are on (`ruby -W:deprecated`). Use `set_content_format` and `config.meta.*` instead.

### Errors

Every libshout error is raised as a subclass of `Shout::ShoutError`, so `rescue Shout::ShoutError` catches them all. The message is libshout's own error text where available.

| Class | libshout error |
|---|---|
| `Shout::InsaneError` | `SHOUTERR_INSANE`: invalid parameters or state |
| `Shout::ConnectionError` | `SHOUTERR_NOCONNECT`: couldn't connect (also network errors in HTTP metadata updates) |
| `Shout::LoginError` | `SHOUTERR_NOLOGIN`: the server rejected the login |
| `Shout::SocketIOError` | `SHOUTERR_SOCKET`: error while talking to the server |
| `Shout::MallocError` | `SHOUTERR_MALLOC`: out of memory |
| `Shout::MetadataError` | `SHOUTERR_METADATA`: metadata update failed |
| `Shout::ConnectedError` | `SHOUTERR_CONNECTED`: can't change this while connected |
| `Shout::UnconnectedError` | `SHOUTERR_UNCONNECTED`: not connected |
| `Shout::UnsupportedError` | `SHOUTERR_UNSUPPORTED`: not supported by this server, protocol or format |
| `Shout::BusyError` | `SHOUTERR_BUSY`: busy, try again later (non-blocking mode) |
| `Shout::NoTLSError` | `SHOUTERR_NOTLS`: TLS requested but not available |
| `Shout::TLSBadCertError` | `SHOUTERR_TLSBADCERT`: the server's TLS certificate failed verification |
| `Shout::RetryError` | `SHOUTERR_RETRY`: try again |

`Shout::SocketIOError` used to be called `Shout::SocketError`. The old name still works but is deprecated, because inside `module Shout` it hid Ruby's own `::SocketError`.

### libshout Version

`Shout.version` describes the loaded libshout library:

```ruby
Shout.version.to_s        # => "2.4.6"
Shout.version >= "2.4.6"  # => true
```

### Low-level libshout Functions

Every function in `shout.h` is attached to `Shout::Native`, an `FFI::Library`, for anything `Shout::Connection` doesn't cover. `Native.shout_new` returns a handle that frees itself when it is garbage collected, and settings with libshout constants take and return symbols:

```ruby
shout = Shout::Native.shout_new
Shout::Native.shout_set_protocol(shout, :icy)
Shout::Native.shout_get_protocol(shout)  # => :icy
```

These functions return libshout's error codes instead of raising, and their API follows libshout rather than this gem.

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

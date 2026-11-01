# Contributing to ffi-shout

## Setup

You need libshout 2.4.6 or newer with its development files (see [Requirements](README.md#requirements) in the README), and the Ruby version from `.ruby-version` (3.4.12). Most Ruby version managers (such as chruby, rbenv, asdf or mise) pick that file up. Then install the dependencies:

```bash
bundle install
```

## Commands

| Command | What it does |
|---|---|
| `bundle exec rake` | Runs the unit specs and RuboCop |
| `bundle exec rspec` | Runs the unit specs only |
| `bundle exec rake spec:integration` | Runs the integration specs (see below) |
| `bundle exec rubocop` | Lints the code (`-a` fixes what it safely can) |
| `COVERAGE=1 bundle exec rspec` | Also writes a coverage report to `coverage/lcov.info` |

Before you open a pull request, `bundle exec rake` should pass without failures or RuboCop offenses.

## Supported Ruby versions

Changes must work on every Ruby version that the [CI workflow](.github/workflows/ci.yml) tests: currently Ruby 3.2, 3.3, 3.4 and 4.0. The gemspec requires Ruby 3.2 or newer, so don't use language features or standard library methods that are newer than that, and don't write specs that depend on the output format of one Ruby version (Ruby 3.4, for example, changed `Hash#inspect`).

CI also runs the specs on ruby-head, JRuby and TruffleRuby. Failures there don't fail the workflow, but please keep them passing where you can. On TruffleRuby, closing a socket doesn't wake a thread blocked on it, which is why the fake HTTP server in the specs kills its thread instead.

To check another Ruby version locally, switch to it with your Ruby version manager, then install the dependencies and run the specs:

```bash
bundle install
bundle exec rspec
```

`Gemfile.lock` is committed and resolved on Ruby 3.2, the oldest supported version, so every tested Ruby version can install it. When you add or update a gem, resolve it on Ruby 3.2 too: on a newer Ruby, Bundler may pick versions that Ruby 3.2 can't install. Dependabot proposes weekly updates, and CI checks them on all Ruby versions.

## Running the integration specs

The integration specs (`spec/integration`) stream to a real Icecast server and check the results through its `/status-json.xsl` page. They are skipped by default; CI runs them against Icecast 2.4.4 (Ubuntu 24.04) and 2.5.0 (Ubuntu 26.04).

They need a local Icecast 2 server with its default settings: port 8000 and source password `hackme`. The specs stream to the mount `/stream.mp3`, which doesn't need to be configured: Icecast accepts sources on any mount unless `icecast.xml` restricts it. Start Icecast and run the specs:

```bash
icecast2 -c /etc/icecast2/icecast.xml   # or `icecast -c ...`, depending on your distribution
bundle exec rake spec:integration
```

For a server that is set up differently, override the defaults with `ICECAST_HOST`, `ICECAST_PORT` and `ICECAST_SOURCE_PASSWORD`:

```bash
ICECAST_PORT=9000 ICECAST_SOURCE_PASSWORD=secret bundle exec rake spec:integration
```

`bundle exec rspec --tag integration` runs them together with the unit specs. The specs also expect nothing to listen on port 59999, which they use as an unreachable server. They run each connection in a forked process, so they need a platform with `fork` (not Windows).

## Code layout

- `lib/shout/native.rb` and `lib/shout/native/` hold the libshout bindings: `Shout::Native` is the `FFI::Library` with an `attach_function` for every function in `shout.h`. Keep these declarations in the order of `shout.h`.
- The rest of `lib/shout/` is the Ruby API (`Connection`, `Configuration`, `Metadata`, the error classes) built on top of `Shout::Native`.
- Specs mirror `lib/` under `spec/shout/`.

## Changelog

Describe user-visible changes in [CHANGELOG.md](CHANGELOG.md).

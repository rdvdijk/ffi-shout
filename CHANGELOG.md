# Changelog

## Unreleased

- Fix `Connection#delay` raising a bogus `Shout::MetadataError` when the stream is behind schedule; it now returns the negative delay.

## 0.1.0

- Initial release.

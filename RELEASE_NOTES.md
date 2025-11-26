# Hungrytable - Ruby API Client for the OpenTable REST API

## v1.0.0 (2025-01-XX)

### Breaking Changes
- Requires Ruby 3.0+
- Replaced `curb` with `http` gem
- Replaced `method_missing` with explicit method definitions

### Changes
- Fixed deprecated `URI.encode`/`URI.decode` → `CGI.escape`/`CGI.unescape`
- Added `oauth` gem for OAuth 1.0
- RuboCop clean, Ruby 3.0+ code style
- Added 152 tests
- Added GitHub Actions CI

---

## v0.0.1 (05/11/2012)

* Get relevant details about an individual restaurant.
* Search for availability at an individual restaurant.

### Known Issues

OpenTable's API currently returns search results as an unsupported transaction,
but it is clearly marked as a thing in their API document.

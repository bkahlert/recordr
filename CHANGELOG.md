# Changelog

## [Unreleased]

### Added

*none*

### Changed

- use [Bats Wrapper GitHub action](https://github.com/marketplace/actions/bats-wrapper)

### Deprecated

*none*

### Removed

*none*

### Fixed

- support `--recordrw:` style arguments also if script is downloaded and executed directly

## [0.2.1] - 2021-11-20

### Changed

- use git.io/recordrw instead of `./recordrw` for GitHub action

## [0.2.0] - 2021-11-15

### Added

- facilitated creation of rec files using interpreter `#!/usr/bin/env recordr`
- `recordrw` self-contained wrapper to run Recordr with minimal effort, e.g. as a one-liner:
  ```shell
  curl -LfsS https://git.io/recordrw | "$SHELL" -s -- [OPTIONS] [DIR[/ ]FILE [FILE...]]
  ```

## [0.1.0] - 2021-10-24

### Added

- `recordr` Bash script and Docker image that enables you to record scripted terminal sessions and convert them to SVG in a single step.

[unreleased]: https://github.com/bkahlert/recordr/compare/v0.2.0...HEAD

[0.2.1]: https://github.com/bkahlert/recordr/compare/v0.2.1...v0.2.0

[0.2.0]: https://github.com/bkahlert/recordr/compare/v0.2.0...v0.1.0

[0.1.0]: https://github.com/bkahlert/recordr/releases/tag/v0.1.0

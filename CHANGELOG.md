# Changelog

## [Unreleased]

### Added

*none*

### Changed

*none*

### Deprecated

*none*

### Removed

*none*

### Fixed

*none*

## [0.2.5] - 2026-10-23

### Changed

- use the same vendored Logr v0.6.6 source in tests and container builds

### Fixed

- run the downloaded action wrapper with Bash regardless of its executable bit

## [0.2.4] - 2026-10-21

### Changed

- refresh Docker base image to `29.9.2-alpine3.24`
- upgrade Logr to the published `v0.6.5` asset
- update the test reporter to `v3.2.0`
- update documented GitHub Actions pins and output handling

## [0.2.3] - 2026-10-21

### Changed

- use [Bats Wrapper GitHub action](https://github.com/marketplace/actions/bats-wrapper)
- refresh container and GitHub Actions dependencies

### Fixed

- write Asciinema recordings as asciicast v2 for svg-term-cli compatibility
- preserve visible recording output and the requested locale with Asciinema 3
- render the info icon as text rather than emoji
- write GitHub Action outputs through the supported output file
- skip artifact upload when the docs workflow does not generate files

## [0.2.2] - 2021-12-10

### Fixed

- set valid `$SHELL` for app user

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

[unreleased]: https://github.com/bkahlert/recordr/compare/v0.2.5...HEAD

[0.2.5]: https://github.com/bkahlert/recordr/compare/v0.2.4...v0.2.5

[0.2.4]: https://github.com/bkahlert/recordr/compare/v0.2.3...v0.2.4

[0.2.3]: https://github.com/bkahlert/recordr/compare/v0.2.2...v0.2.3

[0.2.2]: https://github.com/bkahlert/recordr/compare/v0.2.1...v0.2.2

[0.2.1]: https://github.com/bkahlert/recordr/compare/v0.2.0...v0.2.1

[0.2.0]: https://github.com/bkahlert/recordr/compare/v0.1.0...v0.2.0

[0.1.0]: https://github.com/bkahlert/recordr/releases/tag/v0.1.0

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]
### Added
- Added an LetsEncrypt guide to the README, including the scripts to communicate with LetsEncrypt.

## [1.0.2] - 2019-05-11
### Fixed
- Fixed issue with the non-interactive printer https://github.com/gfish/sprinkle_dns/commit/1e43591c46e056aab9711ccb37eaf91c904969cc

## [1.0.1] - 2019-05-10
### Added
- Introduced the `show_untouched: false` configuration option that will tell the differ to hide the entries that aren't created/updated/deleted, https://github.com/gfish/sprinkle_dns/commit/6e8c003d723bcdb20957200a6e22ffb324003b5d
- Introduced a premature exit in case of no changes detected, https://github.com/gfish/sprinkle_dns/commit/9c88b20a8c005092bfbe0902499156206eed4666

### Fixed
- There is a bug where Route53 will not allow you to change the order of entry-values, so when we compare it looks like the entries need an update, that was solved by sorting before we compare, https://github.com/gfish/sprinkle_dns/commit/d6358f5413fd1652f496b9a4d625b1cbf381e9ca

## [1.0.0] - 2019-05-10
### Added
- Support for having setting configuration options that changes how SprinkleDNS behaves.
- Support for printing a diff with the configuration option `diff: true`.
- Support for ALIAS-entries with the `.alias`-method, before we only had the `.entry`-method.
- Support for deleting entries that aren't referenced.
- Support for creating hosted zones if they are referenced, but don't exist yet.
- Updated the README with configuration examples and AWS policy.

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project will try its best to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Additions

- Add `j` and `k` keys as substitutes for `↑` and `↓`.
- Allow exiting the program with the `esc` key.
- Add ability to grant access privileges for newly created users.
- Or grant privileges for existing users to database(s).

### Fixes

- GitHub now running CI successfully.
- Newly created databases are no longer open for connection by default. `CONNECT` is revoked by default for them.
- When dropping users, loop through all the databases they have access to and revoke access before dropping them.

## [0.1.0] - 2024-08-30

- Initial release
- Create database ✅
- Create user ✅
- Drop database ✅
- Drop user ✅
- List databases ✅

[Unreleased]: https://github.com/jayroh/pgchief/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/jayroh/pgchief/releases/tag/v0.1.0

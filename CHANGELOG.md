# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project will try its best to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Additions

### Changes

* Update restore command to only act on objects `--if-exists` (if they exist)

### Fixes

* Fix method signature in `Database::Backups` - `remote` should be a kwarg and should
  pass it along as such.
* When backing up a database, we add the db name to the end of the pg connection string.
  In cases where that DATABASE_URL already has the database name tacked on at the end,
  make sure it's only there once.

## [0.5.4]

### Additions

* Improve CLI usability with `--version` and `--help` flags.
* Adds `--remote-backup` and `--remote-restore` CLI options.
* Modifies `DatabaseRestore` and prompt flows to conditionally operate on remote backups.
* Adds `--restore database_name` option to cli to quickly restore latest backup for a provided database.

### Changes

* Updates the config loader to respect CLI flags and TOML values for remote_backup and remote_restore.

## [0.5.3]

### Additions

* Add spec for database backup command class.
* Add check on the resulting db dump file. Make sure it's > 0 bytes.

### Changes

* Allow created users the proper permissions to add PG extensions to a database.

### Fixes

* Fix typo in backup command class description.
* Fix backup command to use full database connection string to the database when
  executing the pg_dump command.
* Reset s3 config in db backup spec to prevent config leaks from other test runs.

## [0.5.2]

### Changes

* Change S3 config option `s3_path_prefix` to `s3_objects_path`.
* Above change retains backwards compatibility with the old `s3_path_prefix` option.

### Fixes

* Fix S3 regex to allow `-` in the path.

## [0.5.1]

### Changes

* Update README to note that libpq-dev is a required dependency in order to build.

### Fixes

* Remove `pry` from being required.

## [0.5.0]

### Additions

* Restore database from local file(s).
* Restore database from s3.

## [0.4.0]

### Changes

* Clean up the config object.

### Additions

* Back up option for databases: save to local filesystem or S3.

### Fixes

* Capture error where the config file does not exist and provide some guidance.
* Make a `PG::ConnectionBad` error a little less scary(?).
* Do not inherit the base `Command` class in `ConfigCreate`. It doesn't need to connect to the DB.

## [0.3.1]

### Changes

- The main database url will be accessed via the config class and will prioritize
  the ENV over the config file, if it is set.

### Fixes

- Do not use the ENV only. Until now that was the only method and it was ignoring
  what was set in the config file. This fixes the issue where nothing will work
  if `ENV["DATABASE_URL"]` is not set.

## [0.3.0]

### Additions

- Refactor `exe/pgchief` to utilize `TTY::Option` for kicking off config initialization.
- `pgchief --init` now creates a toml config file in your `$HOME`.
- Added ability to store credentials if your config sets `credentials_file`
  when db's and users are created.
- Added `ConnectionString` class that abstracts the base db connection,
  allowing for additions of users and db's.
- Load everything in the config file to the Config attributes.

### Changes

- Default location of config changed from `~/.pgchief.toml` to `~/.config/pgchief/config.toml`.
- Automatically require 'pry' in the test suite.

### Fixes

- When dropping user, ignore whenever a database has no privileges for the
  selected user.
- Retroactive addition of tests to cover any regressions.

## [0.2.0] - 2024-08-30

### Additions

- Add `j` and `k` keys as substitutes for `↑` and `↓`.
- Allow exiting the program with the `esc` key.
- Add ability to grant access privileges for newly created users.
- Or grant privileges for existing users to database(s).

### Fixes

- GitHub now running CI successfully.
- Newly created databases are no longer open for connection by default.
  `CONNECT` is revoked by default for them.
- When dropping users, loop through all the databases they have access to and
  revoke access before dropping them.

## [0.1.0] - 2024-08-30

- Initial release
- Create database ✅
- Create user ✅
- Drop database ✅
- Drop user ✅
- List databases ✅

[Unreleased]: https://github.com/jayroh/pgchief/compare/v0.5.3...HEAD
[0.5.3]: https://github.com/jayroh/pgchief/releases/tag/v0.5.3
[0.5.2]: https://github.com/jayroh/pgchief/releases/tag/v0.5.2
[0.5.1]: https://github.com/jayroh/pgchief/releases/tag/v0.5.1
[0.5.0]: https://github.com/jayroh/pgchief/releases/tag/v0.5.0
[0.4.0]: https://github.com/jayroh/pgchief/releases/tag/v0.4.0
[0.3.1]: https://github.com/jayroh/pgchief/releases/tag/v0.3.1
[0.3.0]: https://github.com/jayroh/pgchief/releases/tag/v0.3.0
[0.2.0]: https://github.com/jayroh/pgchief/releases/tag/v0.2.0
[0.1.0]: https://github.com/jayroh/pgchief/releases/tag/v0.1.0

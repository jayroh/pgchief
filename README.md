# pgchief

I don't need [an entire web application](https://www.pgadmin.org/) to manage
some self-hosted postgres servers.

I also don't have the entirety of every PG command to back up and restore
databases, manage users, assign permissions to databases, etc, catalogued in my
brain. (That space is reserved for ... I don't know, obscure comic book characters)

Now, what *would* be helpful? That is to have something that assists in some of those
DB maintenance tasks with a clean and straight-forward CLI interface.

Hence, why I am making this `pgchief` thing. It's a simple ruby script utilizing
the [tty-prompt](https://github.com/piotrmurach/tty-prompt) ruby gem to collect
necessary info, and do the proper work for me.

***

*NOTE*: Very little has been built. This is in active pre-alpha development. See
below for the feature check-list and current progress.

***

## Usage

```sh
# System dependency `libpq-dev` must be installed
gem install pgchief

# To initialize the config file at `~/.config/pgchief/config.toml`:

pgchief --init

# edit the config file and set your main administrative connection string
# (vim|nano|pico|ed) ~/.config/pgchief/config.toml

# OR ... make sure the DATABASE_URL env is set to the connection string
# export DATABASE_URL=postgresql://postgres:password@postgres.local:5432

pgchief

# Full usage:

$ pgchief --help
Options:
  -h, --help            Print usage
  -i, --init            Initialize the TOML configuration file
      --remote-backup   Backup a database to a remote location
      --remote-restore  Restore a database from a remote backup
  -v, --version         Show the version
```

## Config

Format of `~/.config/pgchief/config.toml`

```toml
# Connection string to superuser account at your PG instance
pgurl = "postgresql://username:password@host:5432"

# Directory where db backups will be placed
backup_dir = "~/.pgchief/backups"

# ** OPTIONAL **

# Location of saved database connection strings
# credentials_file = "~/.config/pgchief/credentials"

# S3 config
# ---------
# s3_key = ""
# s3_secret = ""
# s3_region = "us-east-1"
# s3_objects_path = "s3://bucket-name/database-backups/"

# Backup and restore from remote locations?
# remote_restore = false # default: false
# remote_backup = false  # default: false
```

Note:

1. Prompts accept both `↑` and `↓` arrows, as well as `j` and `k`.
2. Pressing the `esc` key at any point amidst a prompt will exit out of the program.

## Development of the gem

1. Clone this repo.
2. `bundle install`
3. `cp .env.sample .env`
4. Edit `.env` and change:
   * `DATABASE_URL` to point to your main pg instance's superuser account with a
     connection string.
   * `TEST_DATABASE_URL` to point to your local pg instance where tests can be
     run against.
5. `bundle exec rake` to run test suite & rubocop.

## The ideal, aspirational, DX

```sh
$ pgchief --init # create the TOML file in your home dir (w/600 permissions)
$ pgchief

Welcome! How can I help?
 ‣ Database management
   User management

# --- Database management: Creating a DB ---

Database management, got it! What's next?
 ‣ Create one
   Drop one
   Back it up
   Restore one

What is the database's name?

# --- Database management: Dropping a DB ---

Which database would you like to drop?
 ‣ fabulous-filly
   great-grape
   faster-fuscia

# --- User management: Create a user ---

User management? Ok! Who and what?
 ‣ Create user
   Allow access to database

What is the user's name?
rando-username

Give "rando-username" access to database(s):
 ‣ ⬡ fabulous-filly
   ⬡ great-grape
   ⬡ faster-fuscia
   ⬡ none of the above

# ... etc.
```

***

## Feature Roadmap

* [x] Create database
* [x] Create user
* [x] Drop database
* [x] Drop user
* [x] List databases
* [x] Give user permissions to use database
* [x] Initialize toml file
* [x] Display connection information
* [x] Back up database locally
* [x] Back up database to S3
* [x] Restore local database
* [x] Restore remote database @ S3
* [ ] Quickly back up via command line option
* [ ] Quickly restore via command line option
* [ ] Task for inclusion in a Rakefile
* [ ] Support environment variables in config

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

## Usage:

```
gem install pgchief

# make sure the DATABASE_URL is set to the connection string for a pg server's superuser
export DATABASE_URL=postgresql://postgres:password@postgres.local:5432

pgchief
```

## Development of the gem

1. Clone this repo.
2. `bundle install`
3. `cp .env.sample .env`
4. Edit `.env` and change:
  * `DATABASE_URL` to point to your main pg instance's superuser account with a connection string.
  * `TEST_DATABASE_URL` to point to your local pg instance where tests can be run against.
5. `bundle exec rake` to run test suite & rubocop.

## The ideal, aspirational, DX:

```
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

Format of `~/.pgchief.toml`

```toml
pgurl = "postgres://username:password@host:5432"
backup_dir = "~/.pg_backups"

# [optional] encryption key (to display hashed passwords)
# encryption_key = "my-password"
```

***

## Feature Roadmap

- [x] Create database
- [x] Create user
- [x] Drop database
- [x] Drop user
- [x] List databases
- [ ] Give user permissions to use database
- [ ] Back up database
- [ ] Restore database
- [ ] Initialize toml file
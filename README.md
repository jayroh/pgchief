# pgchief

I don't need an entire web application to manage some self-hosted postgres
servers.

I also don't have the entirety of every PG command to back up and restore
databases, manage users, assign permissions to databases, etc, catalogued in my
brain.

What *would* be helpful is to have something that assists in some of those
tasks with a clean and intuitive CLI interface.

Hence why I made this `pgchief` thing. It's a simple ruby script utilizing the
[tty-prompt](https://github.com/piotrmurach/tty-prompt) and
[tty-command](https://github.com/piotrmurach/tty-command) rubygems to collect
info, and run the correct commands.

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
```

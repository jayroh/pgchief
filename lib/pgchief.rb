# frozen_string_literal: true

require "pg"
require "tty-prompt"
require "tty-option"
require "aws-sdk-s3"

require "pgchief/cli"
require "pgchief/config"
require "pgchief/config/s3"
require "pgchief/connection_string"
require "pgchief/version"
require "pgchief/database"
require "pgchief/user"

require "pgchief/prompt/base"
require "pgchief/prompt/backup_database"
require "pgchief/prompt/create_database"
require "pgchief/prompt/create_user"
require "pgchief/prompt/database_management"
require "pgchief/prompt/drop_database"
require "pgchief/prompt/drop_user"
require "pgchief/prompt/grant_database_privileges"
require "pgchief/prompt/restore_database"
require "pgchief/prompt/start"
require "pgchief/prompt/user_management"
require "pgchief/prompt/view_database_connection_string"

require "pgchief/command"
require "pgchief/command/base"
require "pgchief/command/config_create"
require "pgchief/command/database_backup"
require "pgchief/command/database_create"
require "pgchief/command/database_drop"
require "pgchief/command/database_list"
require "pgchief/command/database_privileges_grant"
require "pgchief/command/database_restore"
require "pgchief/command/retrieve_connection_string"
require "pgchief/command/s3_upload"
require "pgchief/command/store_connection_string"
require "pgchief/command/user_create"
require "pgchief/command/user_drop"
require "pgchief/command/user_list"

module Pgchief
  class Error < StandardError; end

  module Errors
    class UserExistsError < Error; end
    class DatabaseExistsError < Error; end
    class DatabaseMissingError < Error; end
  end
end

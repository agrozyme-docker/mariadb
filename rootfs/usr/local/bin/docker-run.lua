#!/usr/bin/lua
local core = require("docker-core")

local function build_clause_statements(profile, items)
  local account = string.format("'%s'@'%s'", profile.user, profile.host)

  if (("" ~= profile.database) and ("*" ~= profile.database)) then
    items[#items + 1] = string.format("CREATE DATABASE IF NOT EXISTS %s;", profile.database)
  end

  if (("" ~= profile.user) and ("" ~= profile.database)) then
    items[#items + 1] = string.format("CREATE USER IF NOT EXISTS %s IDENTIFIED BY '%s';", account, profile.password)
    items[#items + 1] = string.format("ALTER USER %s IDENTIFIED BY '%s';", account, profile.password)
    items[#items + 1] = string.format("GRANT ALL ON %s.* TO %s WITH GRANT OPTION;", profile.database, account)
  end

  return items
end

local function build_startup_statements()
  local items = {
    "FLUSH PRIVILEGES;",
    "DELETE FROM mysql.user WHERE user IN ('') OR host NOT IN ('localhost', '%');"
  }

  local profile = {
    user = "root",
    password = core.getenv("MYSQL_ROOT_PASSWORD", ""),
    host = "localhost",
    database = "*"
  }

  build_clause_statements(profile, items)

  profile.host = "%"
  build_clause_statements(profile, items)

  profile.user = core.getenv("MYSQL_USER", "")
  profile.password = core.getenv("MYSQL_PASSWORD", "")
  profile.database = core.getenv("MYSQL_DATABASE", "")
  build_clause_statements(profile, items)

  items[#items + 1] = "FLUSH PRIVILEGES;"
  return items
end

local function setup_database(user)
  local count = 30
  core.run("mysqld_safe --user=%s --no-auto-restart --skip-networking --skip-grant-tables", user.server)

  while (0 < count) do
    os.execute("sleep 1")
    local command = string.format("mysqladmin --protocol=socket --user=%s ping", user.client)

    if (os.execute(command)) then
      break
    end

    core.warn("MySQL init process in progress... ")
    count = count - 1
  end

  if (0 == count) then
    error("MySQL init process failed.", 0)
  end

  local items = build_startup_statements()

  if (0 < #items) then
    core.run(
      'mysql --protocol=socket --user=%s --init-command="SET @@SESSION.SQL_LOG_BIN=0;" -e %q',
      user.client,
      table.concat(items, " ")
    )
  end

  core.run(
    "mysqladmin --protocol=socket --user=%s --password=%q shutdown",
    user.client,
    core.getenv("MYSQL_ROOT_PASSWORD", "")
  )
end

local function install_database(user)
  local data = "/var/lib/mysql"
  core.mkdir(data)

  if (core.test("! -d %s/mysql", data)) then
    return core.run("mysql_install_db --user=%s", user.server)
  else
    return true
  end
end

local function main()
  core.update_user()
  core.clear_path("/run/mysqld", "/var/tmp")
  local user = {client = "root", server = "core"}
  local reset = core.getenv("MYSQL_RESET", "")

  if (install_database(user) or core.boolean(reset)) then
    setup_database(user)
  end

  core.run("mysqld_safe --user=%s", user.server)
end

main()

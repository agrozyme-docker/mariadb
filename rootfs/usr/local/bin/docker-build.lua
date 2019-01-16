#!/usr/bin/lua
local core = require("docker-core")

local function update_setting()
  local pcre = require("rex_pcre")
  local file = "/etc/mysql/my.cnf"
  local text = core.read_file(file)
  local mysqld_setting = {
    "character-set-client-handshake = FALSE",
    "collation_server = utf8mb4_general_ci",
    "character_set_server = utf8mb4",
    'init_connect = "SET NAMES utf8mb4"',
    "user = core",
    "log-error = /var/log/mysql/error.log",
    "skip-name-resolve",
    "skip-host-cache"
  }
  text = pcre.gsub(text, [[^[#\s]*(innodb_buffer_pool_size)[\s]*=.*$]], "%1 = 16M", nil, "im")
  text = pcre.gsub(text, [[^[\s]*(\[client\][#\s]*)$]], "%1 \n" .. "default-character-set = utf8mb4", nil, "im")
  text = pcre.gsub(text, [[^[\s]*(\[mysql\][#\s]*)$]], "%1 \n" .. "default-character-set = utf8mb4", nil, "im")
  text = pcre.gsub(text, [[^[\s]*(\[mysqld\][#\s]*)$]], "%1 \n" .. table.concat(mysqld_setting, "\n"), nil, "im")
  core.write_file(file, text)
  core.append_file(file, "!includedir /usr/local/etc/mysql/ \n")
end

local function replace_setting()
  if (core.has_modules("rex_pcre")) then
    update_setting()
  else
    core.replace_files("/etc/mysql/my.cnf")
  end
end

local function main()
  -- core.run("apk add --no-cache lua-rex-pcre")
  core.run("apk add --no-cache mariadb mariadb-client")
  core.run("mkdir -p /var/log/mysql /usr/local/etc/mysql")
  core.link_log(nil, "/var/log/mysql/error.log")
  replace_setting()
end

main()

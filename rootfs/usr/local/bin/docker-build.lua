#!/usr/bin/lua
local core = require("docker-core")

local function main()
  core.run("apk add --no-cache mariadb mariadb-client")
  core.run("mkdir -p /var/log/mysql /usr/local/etc/mysql")
  core.link_log(nil, "/var/log/mysql/error.log")
  core.append_file("/etc/my.cnf", "\n!includedir /etc/mysql/ \n!includedir /usr/local/etc/mysql/ \n")
end

main()

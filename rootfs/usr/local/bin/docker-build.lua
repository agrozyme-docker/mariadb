#!/usr/bin/lua
local core = require("docker-core")

local function main()
  core.run("apk add --no-cache mariadb mariadb-client")
  core.run("mkdir -p /var/log/mysql /usr/local/etc/mysql")
  core.link_log(nil, "/var/log/mysql/error.log")
  core.append_file("/etc/mysql/my.cnf", "\n!includedir /etc/mysql/docker/ \n!includedir /usr/local/etc/mysql/ \n")
end

main()

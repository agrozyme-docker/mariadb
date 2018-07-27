#!/bin/bash
set -euo pipefail

function main() {
  agrozyme.alpine.function.sh change_core
  agrozyme.mariadb.function.sh
  rm -f /run/mysqld/mysqld.pid
  exec mysqld_safe
}

main "$@"

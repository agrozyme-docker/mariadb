#!/bin/bash
set -euo pipefail

function main() {
  agrozyme.alpine.function.sh change_core
  agrozyme.alpine.function.sh empty_folder /run/mysqld /var/tmp
  agrozyme.mariadb.function.sh
  exec mysqld_safe --user=core
}

main "$@"

#!/bin/bash

function execute_statement() {
  local statement=${1}

  if [ -n "${statement}" ]; then
    mysql --protocol=socket --user=root -e "${statement}"
  fi
}

function start_database() {
  mysqld_safe --nowatch --skip-grant-tables
  local count

  for count in {30..0}; do
    if execute_statement 'SELECT 1' &> /dev/null; then
      break
    fi
    echo 'MySQL init process in progress...'
    sleep 1
  done

  if [ "${count}" = 0 ]; then
    echo >&2 'MySQL init process failed.'
    exit 1
  fi
}

function build_statement() {
  declare -A items
  eval "items=${1#*=}"

  local user=${items['user']}
  local password=${items['password']}
  local host=${items['host']:-localhost}
  local database=${items['database']}

  local account="'${items[user]}'@'${items[host]}'"
  local statement

  if [ -n "${database}" -a "*" != "${database}" ]; then
    statement+=$(
      cat <<- SQL

      CREATE DATABASE IF NOT EXISTS ${database};
SQL
    )
  fi

  if [ "${user}" -a "${database}" ]; then
    statement+=$(
      cat <<- SQL

      CREATE USER IF NOT EXISTS ${account} IDENTIFIED BY '${password}';
      ALTER USER ${account} IDENTIFIED BY '${password}';
      GRANT ALL ON ${database}.* TO ${account} WITH GRANT OPTION;
SQL
    )
  fi

  echo "${statement}"
}

function install_database() {
  local data=/var/lib/mysql

  if [ -d "${data}/mysql" ]; then
    return
  fi

  mkdir -p "${data}"
  chown -R mysql:mysql "${data}"
  mysql_install_db --user=mysql
}

function main() {
  declare -A items=(
    ['user']=root
    ['password']=${MYSQL_ROOT_PASSWORD}
    ['host']=localhost
    ['database']=*
  )

  local install=$(install_database)

  if [ -z "${install}" -a "${MYSQL_RESET}" != "YES" ]; then
    return
  fi

  start_database

  local statement
  statement+=$(
    cat <<- SQL

    SET @@SESSION.SQL_LOG_BIN=0;
    FLUSH PRIVILEGES;
    DELETE FROM mysql.user WHERE user IN ('') OR host NOT IN ('localhost', '%');
SQL
  )

  statement+=$(build_statement "$(declare -p items)")
  items['host']=%
  statement+=$(build_statement "$(declare -p items)")

  items+=(
    ['user']=${MYSQL_USER}
    ['password']=${MYSQL_PASSWORD}
    ['host']=%
    ['database']=${MYSQL_DATABASE}
  )

  statement+=$(build_statement "$(declare -p items)")
  statement+=$(
    cat <<- SQL

    FLUSH PRIVILEGES;
SQL
  )

  execute_statement "${statement}"
  mysqladmin --user=root --password="${MYSQL_ROOT_PASSWORD}" shutdown
}

set -ex
main
rm -f /run/mysqld/mysqld.pid
exec mysqld_safe

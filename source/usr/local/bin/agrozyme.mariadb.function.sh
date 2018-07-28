#!/bin/bash
set -euo pipefail

function execute_statement() {
  local statement=${1}
  
  if [[ -n "${statement}" ]]; then
    mysql --protocol=socket --user=root --init-command="SET @@SESSION.SQL_LOG_BIN=0;" -e "${statement}"
  fi
}

function build_clause_statement() {
  declare -A items
  eval "items=${1#*=}"
  
  local user=${items['user']}
  local password=${items['password']}
  local host=${items['host']:-localhost}
  local database=${items['database']}
  
  local account="'${items[user]}'@'${items[host]}'"
  local statement=""
  
  if [[ -n "${database}" ]] && [[ "*" != "${database}" ]]; then
    statement+=$(
      cat <<- SQL

      CREATE DATABASE IF NOT EXISTS ${database};
SQL
    )
  fi
  
  if [[ -n "${user}" ]] && [[ -n "${database}" ]]; then
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

function build_startup_statement() {
  declare -A mysql
  eval "mysql=${1#*=}"
  
  local statement=""
  statement+=$(
    cat <<- SQL

    FLUSH PRIVILEGES;
    DELETE FROM mysql.user WHERE user IN ('') OR host NOT IN ('localhost', '%');
SQL
  )
  
  declare -A items=(
    ['user']=root
    ['password']=${mysql['ROOT_PASSWORD']}
    ['host']=localhost
    ['database']=*
  )
  
  statement+=$(build_clause_statement "$(declare -p items)")
  items['host']=%
  statement+=$(build_clause_statement "$(declare -p items)")
  
  items+=(
    ['user']=${mysql['USER']}
    ['password']=${mysql['PASSWORD']}
    ['host']=%
    ['database']=${mysql['DATABASE']}
  )
  
  statement+=$(build_clause_statement "$(declare -p items)")
  statement+=$(
    cat <<- SQL

    FLUSH PRIVILEGES;
SQL
  )
  
  echo "$statement"
}

function install_database() {
  local data=/var/lib/mysql
  mkdir -p "${data}"
  chown -R core:core "${data}" /run/mysqld
  
  if [[ ! -d "${data}/mysql" ]]; then
    mysql_install_db
  fi
}

function setup_database() {
  declare -A mysql
  eval "mysql=${1#*=}"
  
  mysqld_safe --nowatch --skip-grant-tables
  local count=""
  
  for count in {30..0}; do
    if mysqladmin --protocol=socket --user=root ping &> /dev/null; then
      break
    fi
    echo 'MySQL init process in progress...'
    sleep 1
  done
  
  if [[ 0 == ${count} ]]; then
    echo >&2 'MySQL init process failed.'
    exit 1
  fi
  
  local statement=$(build_startup_statement "$(declare -p mysql)")
  execute_statement "${statement}"
  mysqladmin --user=root --password="${mysql['ROOT_PASSWORD']}" shutdown
}

function main() {
  declare -A mysql=(
    ['ROOT_PASSWORD']=${MYSQL_ROOT_PASSWORD:-}
    ['DATABASE']=${MYSQL_DATABASE:-}
    ['USER']=${MYSQL_USER:-}
    ['PASSWORD']=${MYSQL_PASSWORD:-}
    ['RESET']=${MYSQL_RESET:-}
  )
  
  local install=$(install_database)
  
  if [[ -n "${install}" ]] || [[ "YES" == "${mysql['RESET']}" ]]; then
    setup_database "$(declare -p mysql)"
  fi
}

main "$@"

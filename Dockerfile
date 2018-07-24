FROM agrozyme/alpine:3.8
COPY source /

RUN set -euxo pipefail \
  && chmod +x /usr/local/bin/*.sh \
  && apk add --no-cache mariadb mariadb-client \
  && mkdir -p /run/mysqld /var/log/mysql /usr/local/etc/mysql /var/lib/mysql \
  && chown -R core:core /run/mysqld /var/lib/mysql \
  && ln -sf /dev/stderr /var/log/mysql/error.log \
  && sed -ri \
    -e '/^\[client\]$/a default-character-set = utf8mb4' \
    -e '/^\[mysql\]$/a default-character-set = utf8mb4' \
    -e '/^\[mysqld\]$/a character-set-client-handshake = FALSE' \
    -e '/^\[mysqld\]$/a collation_server = utf8mb4_general_ci' \
    -e '/^\[mysqld\]$/a character_set_server = utf8mb4' \
    -e '/^\[mysqld\]$/a init_connect = "SET NAMES utf8mb4" ' \
    -e '/^\[mysqld\]$/a user = core' \
    -e '/^\[mysqld\]$/a log-error = /var/log/mysql/error.log' \
    -e '/^\[mysqld\]$/a skip-name-resolve' \
    -e '/^\[mysqld\]$/a skip-host-cache' \
    -e '$ a !includedir /usr/local/etc/mysql/' \
    /etc/mysql/my.cnf

EXPOSE 3306
CMD ["agrozyme.mariadb.command.sh"]

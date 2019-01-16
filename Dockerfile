FROM agrozyme/alpine:3.8
COPY rootfs /
RUN set +e -uxo pipefail && chmod +x /usr/local/bin/* && /usr/local/bin/docker-build.lua
EXPOSE 3306
CMD ["/usr/local/bin/mariadb.lua"]

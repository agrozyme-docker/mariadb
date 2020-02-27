FROM docker.io/agrozyme/alpine:3.11
COPY rootfs /
RUN set +e -uxo pipefail && chmod +x /usr/local/bin/* && /usr/local/bin/docker-build.lua
EXPOSE 3306
CMD ["/usr/local/bin/docker-run.lua"]

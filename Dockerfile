FROM ghcr.io/nforceroh/alpine-base:3.24

ARG \
  BUILD_DATE=now \
  VERSION=unknown 

LABEL \
  org.label-schema.maintainer="Sylvain Martin (sylvain@nforcer.com)" \
  org.label-schema.build-date="${BUILD_DATE}" \
  org.label-schema.version="${VERSION}" \
  org.label-schema.vcs-url="https://github.com/nforceroh/rspamd" \
  org.label-schema.vcs-ref="${VERSION}" \
  org.label-schema.schema-version="1.0"

### Disable Features From Base Image
ENV ENABLE_SMTP=false \
    ADMIN_PASS='$2$s3dymobyg84ktaksyhkf8der7juzcnza$omo3btjw5kkawjpsnwx4teh7xfny7136aw9xk1a5w6r3ay4714rb' \
    REDIS_HOST=redis-master.databases.svc.cluster.local \
    REDIS_PORT=6379 \
    REDIS_TIMEOUT=15s \
    REDIS_DB=7 \
    CLAMAV_HOST=clamav.mail.svc.cluster.local \
    CLAMAV_PORT=3310 \
    LOG_LEVEL=info \
    DEBUG_MODE=false
# error,warning,info,debug

### Install Dependencies
RUN apk update \
    && apk upgrade \
    && apk add --no-cache bash ca-certificates rspamd rspamd-client rspamd-utils rspamd-libs rspamd-controller rspamd-proxy rspamd-fuzzy redis \
 ## Cleanup
    && rm -rf /var/cache/apk/* /usr/src/*

### Add Files
ADD --chmod=755 /content/etc/s6-overlay /etc/s6-overlay
ADD --chmod=644 /content/assets /assets

VOLUME [ "/var/lib/rspamd" ]

### Networking Configuration
# Port 11334 is for web frontend
# Port 11332 is for milter
# Port 11333 is for worker
EXPOSE 11332 11333 11334

ENTRYPOINT [ "/init" ]
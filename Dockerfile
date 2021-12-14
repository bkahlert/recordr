FROM docker:20.10.12-alpine3.14

# build time only options
ARG LOGR_VERSION=0.6.2
ARG APP_USER=recordr
ARG APP_GROUP=$APP_USER

# build and run time options
ARG DEBUG=0
ARG TZ=UTC
ARG LANG=C.UTF-8
ARG PUID=1000
ARG PGID=1000

# dependencies
# as of 2021-06-21 BusyBox's sed does not seem to properly support curly quantifiers; therefore GNU sed
RUN apk --no-cache --update add \
    asciinema \
    bash \
    ca-certificates \
    curl \
    dumb-init \
    docker-cli \
    expect \
    nodejs \
    npm \
    sed \
    shadow \
 && npm install -g svg-term-cli

# app setup
COPY --from=crazymax/yasu:1.17.0 / /
COPY rootfs /
COPY recordr /usr/local/bin/
RUN chmod +x \
    /usr/local/sbin/entrypoint.sh \
    /usr/local/bin/entrypoint_user.sh \
    /usr/local/bin/recordr \
 && sed -Ei -e "s/([[:space:]]app_user=)[^[:space:]]*/\1$APP_USER/" \
            -e "s/([[:space:]]app_group=)[^[:space:]]*/\1$APP_GROUP/" \
             /usr/local/sbin/entrypoint.sh \
 && curl -LfsSo /usr/local/bin/logr.sh https://github.com/bkahlert/logr/releases/download/v${LOGR_VERSION}/logr.sh

# env setup
ENV DEBUG="$DEBUG" \
    TZ="$TZ" \
    LANG="$LANG" \
    PUID="$PUID" \
    PGID="$PGID"

# user setup
RUN groupadd \
    --gid "$PGID" \
    "$APP_GROUP" \
 && useradd \
    --comment "app user" \
    --uid $PUID \
    --gid "$APP_GROUP" \
    --shell /bin/bash \
    "$APP_USER"

# finalization
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/usr/local/sbin/entrypoint.sh"]

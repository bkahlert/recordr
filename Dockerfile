FROM docker:20.10.10-alpine3.14

# build time only options
ARG APP_USER=recordr
ARG APP_GROUP=$APP_USER

# build and run time options
ARG TZ=UTC
ARG LANG=C.UTF-8
ARG PUID=1000
ARG PGID=1000

# dependencies
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
             /usr/local/sbin/entrypoint.sh
#&& curl -LfsSo /usr/local/bin/recordr.sh https://raw.githubusercontent.com/bkahlert/recordr/master/recordr.sh

# env setup
ENV TZ="$TZ" \
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
    --shell /sbin/nologin \
    "$APP_USER" \
 && rm -rf /tmp/* /var/lib/apt/list/*

# finalization
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/usr/local/sbin/entrypoint.sh"]

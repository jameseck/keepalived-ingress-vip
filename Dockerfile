FROM alpine:3.17

ENV GOMPLATE_VERSION=v3.11.5 \
    GOMPLATE_BASEURL=https://github.com/hairyhenderson/gomplate/releases/download \
    DUMBINIT_VERSION=v1.2.5 \
    DUMBINIT_BASEURL=https://github.com/Yelp/dumb-init/releases/download/ \
    KEEPALIVED_VERSION=2.2.7-r2

ARG TARGETPLATFORM

# Install keepalived
RUN apk add --no-cache file ca-certificates bash coreutils curl net-tools jq keepalived=${KEEPALIVED_VERSION} \
  && rm -f /etc/keepalived/keepalived.conf \
  && addgroup -S keepalived_script && adduser -D -S -G keepalived_script keepalived_script

COPY keepalived.conf.tmpl /etc/keepalived/keepalived.conf.tmpl
COPY vrrp_check.sh /opt/bin/vrrp_check.sh

RUN case ${TARGETPLATFORM} in \
         "linux/amd64")  TARGETARCH=amd64 ; DUMBINIT_ARCH=x86_64  ;; \
         "linux/arm64")  TARGETARCH=arm64 ; DUMBINIT_ARCH=aarch64 ;; \
         "linux/arm/v7") TARGETARCH=armv7 ; DUMBINIT_ARCH=aarch64 ;; \
         "linux/arm/v6") TARGETARCH=armv6 ; DUMBINIT_ARCH=aarch64 ;; \
    esac && \
    curl -sL ${GOMPLATE_BASEURL}/${GOMPLATE_VERSION}/gomplate_linux-${TARGETARCH} --output /bin/gomplate && \
    curl -sL ${DUMBINIT_BASEURL}/${DUMBINIT_VERSION}/dumb-init_$(echo $DUMBINIT_VERSION | sed -e 's/^v//')_${DUMBINIT_ARCH} --output /bin/dumb-init && \
    chmod +x /bin/gomplate /bin/dumb-init

ENTRYPOINT ["/bin/dumb-init", "--", \
            "/bin/gomplate", "-f", "/etc/keepalived/keepalived.conf.tmpl", "-o", "/etc/keepalived/keepalived.conf", "--" \
]

CMD [ "/usr/sbin/keepalived", "-l", "-n", "-f", "/etc/keepalived/keepalived.conf" ]

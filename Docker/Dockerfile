FROM alpine:3.12

RUN apk add --no-cache --update postfix cyrus-sasl cyrus-sasl-plain ca-certificates bash && \
    apk add --no-cache --upgrade musl musl-utils && \
    (rm "/tmp/"* 2>/dev/null || true) && (rm -rf /var/cache/apk/* 2>/dev/null || true)

EXPOSE 25 587

VOLUME [ "/var/spool/postfix", "/etc/postfix" ]

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

# Start postfix in foreground mode
CMD ["postfix", "start-fg"]

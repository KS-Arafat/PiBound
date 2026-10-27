FROM pihole/pihole:latest

RUN apk add --no-cache unbound curl dnssec-root ca-certificates \
 && mkdir -p /var/lib/unbound \
 && curl -fsSL -o /var/lib/unbound/root.hints https://www.internic.net/domain/named.root \
 && chown -R unbound:unbound /var/lib/unbound

COPY unbound/unbound-pihole.conf /etc/unbound/unbound.conf.d/pi-hole.conf
COPY entrypoint.sh /usr/local/bin/pihole-entrypoint

RUN chmod +x /usr/local/bin/pihole-entrypoint

ENTRYPOINT ["/usr/local/bin/pihole-entrypoint"]

FROM alpine:3.18

# Nginx and OpenSSL clean install + Paths for processes and certificates
RUN apk add --no-cache nginx openssl \
    && mkdir -p /etc/nginx/ssl /var/run/nginx

# Copy config file
COPY conf/nginx.conf /etc/nginx/http.d/default.conf

# Copy entrypoint script that generates certificates + permissions
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443

# Script takes control when starting container
ENTRYPOINT ["/entrypoint.sh"]


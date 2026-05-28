FROM alpine:3.18

# Nginx and OpenSSL clean install
RUN apk add --no-cache nginx openssl

# Paths for processes and certificates
RUN mkdir -p /etc/nginx/ssl /var/run/nginx

# Copy config file
COPY conf/nginx.conf /etc/nginx/http.d/default.conf

# Copy entrypoint script that generates certificates
RUN chmod +x /entrypoint.sh

EXPOSE 443

# Script takes control when starting container
ENTRYPOINT ["/entrypoint.sh"]


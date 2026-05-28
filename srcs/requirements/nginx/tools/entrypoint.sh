#!/bin/sh
set -eu

# Generate certificate dinamically, if it doesn't exist yet, using .env 
if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=vjan-nie/CN=${DOMAIN_NAME}"
fi

# Replace shell process so Nginx becomes PID 1
exec nginx -g "daemon off;"


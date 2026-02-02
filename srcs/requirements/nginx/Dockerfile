FROM debian:bullseye

RUN apt-get update && apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

# Set necessary paths
RUN mkdir -p /etc/nginx/ssl /var/run/nginx /var/www/html

# Generate certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=vjan-nie/CN=vjan-nie.42.fr"

# Replace default configuration with our own
RUN rm -f /etc/nginx/sites-enabled/default
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

# Permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]

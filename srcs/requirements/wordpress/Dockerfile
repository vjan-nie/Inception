FROM alpine:3.22

# Unify dependency install, WP-CLI download, and permission adjustments in just one RUN (just one layer)
RUN apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-json \
    php83-openssl \
    php83-curl \
    php83-zlib \
    php83-xml \
    php83-phar \
    php83-intl \
    php83-dom \
    php83-xmlwriter \
    php83-xmlreader \
    php83-ctype \
    php83-session \
    php83-mbstring \
    curl \
    mariadb-client \
    && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && addgroup -S nginx \
    && adduser -S -G nginx nginx \
    && echo "memory_limit=256M" > /etc/php83/conf.d/50_memory.ini

# Copy config files
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Adjust script's permission after copy
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["php-fpm83", "-F"]
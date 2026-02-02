#!/bin/sh
set -e

# Wait for MariaDB
echo "Waiting for MariaDB..."
until mysql -h mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "USE $MYSQL_DATABASE;" >/dev/null 2>&1; do
    sleep 2
done

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "WordPress not found, installing..."

    # Download (--force in case there are leftovers of a failed previous process)
    wp core download --allow-root --force

    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb" \
        --allow-root

    # Install (Admin)
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="Inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="admin@example.com" \
        --allow-root

    # Create normal user
    wp user create "$WP_USER" "user@example.com" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=subscriber \
        --allow-root

    echo "WordPress installed successfully!"
fi

# PHP-FPM runs as www-data
chown -R www-data:www-data /var/www/html

# Execute Dockerfile CMD (php-fpm)
exec "$@"

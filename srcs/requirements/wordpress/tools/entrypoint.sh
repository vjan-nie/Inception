#!/bin/sh
set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

echo "WordPress: Waiting for MariaDB to be ready..."
until mariadb-admin ping -h mariadb --silent >/dev/null 2>&1; do
    sleep 2
done

# If WordPress isn't installes in shared volume, configure
if [ ! -f wp-config.php ]; then
    echo "WordPress: Core not found, downloading and installing..."

    # Clean WordPress download
    wp core download --allow-root --force

    # wp-config.php with .env variables
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb:3306" \
        --allow-root

    # Install domain and define Admin
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root

    # Creat normal user
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --allow-root

    echo "WordPress: Installation completed successfully!"
fi

# Adjust user 'nginx' permissions for Alpine
echo "WordPress: Adjusting volume permissions..."
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html

# Execute Dockerfile's CMD (php-fpm81 -F) as PID 1
exec "$@"

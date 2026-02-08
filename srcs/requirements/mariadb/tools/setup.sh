#!/bin/sh
set -e

# Paths & permissions if database not initialized
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then

  # Explicit volume permissions in case they changed
  chown -R mysql:mysql /var/lib/mysql

  # Backgorund start of MariaDB as mysql
  mysqld_safe --user=mysql --skip-networking &

  # Wait until it's ready
  until mysqladmin ping >/dev/null 2>&1; do
    echo "Waiting for MariaDB to start..."
    sleep 2
  done

  # Create Data Base & Users
  mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

  # Stop background MariaDB, and usenew set password
  mysqladmin -u root -p$MYSQL_ROOT_PASSWORD shutdown
  sleep 2

fi

# Execute original CMD from Dockerfile, which will become PID1
exec mysqld --user=mysql

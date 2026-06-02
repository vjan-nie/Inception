#!/bin/sh
set -eu

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# 1. Make sure that paths and correct permissions exist
mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# 2. Check if system tables exist; if they do not, initialize
if [ ! -d /var/lib/mysql/mysql ]; then

    echo "MariaDB: Initializing system tables..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null

    # 3. Start up temporal server without external network to configure secrets
    echo "MariaDB: Starting temporary server for bootstrap..."
    mariadbd --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
    pid="$!"

    # 4. Safe waiting for socket to answer
    until mariadb-admin --socket=/run/mysqld/mysqld.sock ping --silent >/dev/null 2>&1; do
        echo "Waiting for temporary MariaDB to respond..."
        sleep 1
    done

    # 5. Start DataBase, user, and change Root key
    echo "MariaDB: Configuring database and users..."
    mariadb --socket=/run/mysqld/mysqld.sock <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # 6. Shut the temp server down and wait until it's really dead
    echo "MariaDB: Shutting down temporary server..."
    mariadb-admin --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait "$pid" 2>/dev/null || true
    echo "MariaDB: Bootstrap completed successfully."
fi

# 7. Execute in first plane (turns into PID 1)
# Flags are passed directly here to ensure correct listening outside
echo "MariaDB: Starting production server..."
exec mariadbd --user=mysql --bind-address=0.0.0.0 --port=3306

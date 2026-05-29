FROM alpine:3.18

# 1. Install MAriaDB client and server (to be able to use mariadb-admin)
RUN apk add --no-cache mariadb mariadb-client

# 2. Copy unified config
COPY conf/my.cnf /etc/my.cnf

# 3. Copy entrypoint.sh script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 4. Expose inner database port
EXPOSE 3306

# 5. When starting container, give control to the script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
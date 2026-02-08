# Developer Documentation

## Infrastructure Overview
The infrastructure is composed of three services within a private network (`inception_network`).



### Host Bind Mounts and Permissions
The project uses Bind Mounts for persistence:
- `mariadb_data` -> `/home/${USER}/data/mariadb`
- `wordpress_data` -> `/home/${USER}/data/wordpress`

**Technical Decision:** We run the Makefile with `sudo` because the WordPress container (running as `www-data` inside) creates files that might be difficult to delete from the host without root privileges. The `make fclean` command uses `rm -rf` to ensure a clean state for the next build.

## Implementation Details

### PID 1 and Signaling
To ensure the containers handle `SIGTERM` signals correctly:
- **Nginx**: `daemon off;`
- **MariaDB**: `exec mysqld`
- **PHP-FPM**: `-F` (Foreground mode)

### FastCGI Communication
Nginx communicates with PHP-FPM using the FastCGI protocol on port 9000.

## Maintenance
- **Prune Docker System**: `sudo docker system prune -a`
- **Rebuild from scratch**: `sudo make re`
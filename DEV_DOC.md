# Developer Documentation

## Architecture

Three self-built containers on a private bridge network (`inception_network`), each from a hand-written Dockerfile on **Alpine 3.22**:

- **nginx** — TLS termination; the only published port (443). Proxies PHP requests to WordPress over FastCGI (port 9000).
- **wordpress** — WordPress + PHP-FPM 8.3, running as the `nginx` user.
- **mariadb** — the database.

All three use the `unless-stopped` restart policy.

## Set up from scratch

Prerequisites: Docker + Compose v2, `make`, `git`, and `sudo` (or `docker` group).

Configuration files:

- **`srcs/.env`** — non-sensitive variables: `LOGIN`, `DOMAIN_NAME`, `MYSQL_DATABASE`, `MYSQL_USER`, `WP_TITLE`, `WP_ADMIN_USER`, `WP_ADMIN_EMAIL`, `WP_USER`, `WP_USER_EMAIL`. Bootstrapped from `.env.example`.
- **`secrets/*.txt`** — passwords (DB root, DB user, WP admin, WP user) handled as **Docker secrets**: mounted read-only at `/run/secrets/` and read by the entrypoints at runtime. Bootstrapped from `*.txt.example`; the real files are git-ignored.

Data-path note: the Makefile exports `LOGIN := $(whoami)`, so the Compose bind device (`/home/${LOGIN}/data`) always matches the directories the Makefile creates. It auto-adapts to whoever runs it — no manual editing needed.

## Build and launch

```bash
make            # build (parallel, BuildKit) then `up -d`
make build      # bootstrap .env + secrets, create data dirs, build images
make up / down  # start / stop
make re         # fclean, then full rebuild
make logs / ps / images
```

Compose is always invoked as `docker compose -f srcs/docker-compose.yml --env-file srcs/.env ...`.

## Manage containers and volumes

```bash
docker compose -f srcs/docker-compose.yml ps
docker exec -it wordpress sh
docker compose -f srcs/docker-compose.yml logs -f mariadb
docker volume inspect srcs_db_data            # host bind device
docker network inspect inception_network
# resolved bind paths (variable interpolation applied):
docker compose -f srcs/docker-compose.yml --env-file srcs/.env config | grep -A2 device
```

## Where data lives and how it persists

Two host bind mounts:

- `srcs_db_data`  → `/home/<user>/data/mariadb`  (database)
- `srcs_wp_data`  → `/home/<user>/data/wordpress` (WordPress files, shared with nginx)

Because they are host bind mounts, data survives `make down`/`up` and VM reboots. `make fclean` removes them with `sudo rm -rf` — the WordPress container writes files as the `nginx` user, which is why root is needed for cleanup.

## Implementation details

- **PID 1 / signals:** NGINX runs with `daemon off;`, MariaDB with `exec mariadbd ...`, PHP-FPM with `php-fpm83 -F`. No `tail -f` / `sleep infinity` / infinite loops.
- **Startup ordering:** WordPress waits for MariaDB with an authenticated `mariadb-admin ping`; MariaDB initialises on first run via a temporary `--skip-networking` bootstrap server, then `exec`s the production daemon.
- **Secrets at runtime:** entrypoints read `$(cat /run/secrets/<name>)` into the variables they use — passwords never appear in the image layers, the process environment, or Git.
- **FastCGI:** NGINX forwards `.php` requests to PHP-FPM on port 9000.

## Maintenance

```bash
sudo docker system prune -a    # reclaim space from old images/layers
```
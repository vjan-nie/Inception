# User Documentation

## What this stack provides

Three containers behind a single TLS entry point, on a private Docker network:

- **NGINX** — the only entry point; serves the site over HTTPS on port 443 (TLS 1.2/1.3 only).
- **WordPress + PHP-FPM** — the application.
- **MariaDB** — the database.

Only NGINX is reachable from outside; WordPress and MariaDB are private.

## Requirements

- Linux with **Docker** and **Docker Compose v2**.
- `sudo`, or membership in the `docker` group (the Makefile creates `/home/<user>/data` and manages Docker).

## Domain

The site answers on **`vjan-nie.42.fr`**, which must resolve to where NGINX listens. If you run the stack directly on your machine:

```bash
echo "127.0.0.1 vjan-nie.42.fr" | sudo tee -a /etc/hosts
```

If you run it inside the provisioned VM, browser access is handled by the host-only network — see the `Debian_VM` repository.

## Start and stop the project

```bash
sudo make all      # build the images and start the stack
sudo make down     # stop the stack
sudo make fclean   # remove containers, images, volumes and host data
```

## Access the website and the admin panel

- **Website:** https://vjan-nie.42.fr (self-signed certificate — accept the browser warning when testing locally).
- **Admin panel:** https://vjan-nie.42.fr/wp-admin — log in with the WordPress admin user (see *Credentials*).

## Credentials

Non-sensitive values (domain, database and user names, admin username, emails, site title) live in `srcs/.env`. **Passwords are Docker secrets**, one per file under `secrets/`:

```
secrets/db_root_password.txt
secrets/db_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Running `make` creates these from the committed `*.txt.example` templates if they are missing — **edit them with your own values.** The real `*.txt` files are git-ignored and never leave your machine. To change a password, edit its file and run `make re`. The WordPress admin username is set by `WP_ADMIN_USER` in `.env` (it must not contain "admin").

## Check that the services are running

```bash
docker compose -f srcs/docker-compose.yml ps        # all three should show "Up"
docker compose -f srcs/docker-compose.yml logs -f   # follow logs
curl -k https://localhost                           # should return the WordPress page
```

## Troubleshooting

- **Port 443 busy:** stop any local web server, or change the host port mapping in `srcs/docker-compose.yml`.
- **Permission denied creating host data:** run with `sudo`, or add your user to the `docker` group.
- **Site redirects oddly / wrong host:** confirm the domain resolves correctly and matches `DOMAIN_NAME` in `srcs/.env`.
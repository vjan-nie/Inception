# Inception - @vjan-nie

*This project has been created as part of the 42 curriculum by vjan-nie.*

## Description
**Inception** is a System Administration project designed to broaden knowledge of virtualization and infrastructure-as-code. The goal is to build a high-availability, multi-service architecture using **Docker**. 

The project orchestrates a LEMP-like stack where each service (Nginx, MariaDB, and WordPress) is isolated in its own container, communicating through a private virtual network and ensuring data persistence through local host mapping.

## Project Description & Design Choices

# Inception - @vjan-nie

*This project was created as part of the 42 curriculum by vjan-nie.*

## Description

**Inception** is a System Administration project that builds a small LEMP-like stack using Docker. The stack contains three services (Nginx, WordPress/PHP-FPM, and MariaDB) running in separate containers, connected through a private Docker network and using host bind mounts for persistent data.

## Project sources

The project logic is contained within the `srcs/` directory:

- `docker-compose.yml` — orchestration for services, networks, and volumes
- `requirements/` — Dockerfiles and custom configurations for each service
- `.env` — environment variables used by `docker-compose` (not included in repo!)

## Design comparisons

| Concept | Choice | Reasoning |
| :--- | :--- | :--- |
| VMs vs Docker | Docker | VMs virtualize hardware (heavy). Docker is lighter for service isolation. |
| Docker Network vs Host | Docker Network | Isolates container traffic. |
| Volumes vs Bind Mounts | Bind Mounts | Host-visible data under `$(HOME)/data` for evaluation. |

---

## Instructions

### 1. Prerequisites

- Linux (Debian/Ubuntu recommended)
- Docker and Docker Compose installed
- Sudo privileges or membership in the `docker` group (required for creating host folders and some `make` targets)

### 2. Host configuration

Map the project domain to the local loopback:

```bash
echo "127.0.0.1 vjan-nie.42.fr" | sudo tee -a /etc/hosts
```

### 3. Environment setup

Create a `.env` file in the `srcs/` directory. You can use this template for testing:

```ini
# Domain
DOMAIN_NAME=vjan-nie.42.fr

# MariaDB credentials
MYSQL_DATABASE=inception_db
MYSQL_USER=vjan-nie
MYSQL_PASSWORD=your_user_password
MYSQL_ROOT_PASSWORD=your_root_password

# WordPress credentials
WP_ADMIN_USER=admin_user
WP_ADMIN_PASSWORD=admin_password
WP_ADMIN_EMAIL=admin@example.com

WP_USER=normal_user
WP_USER_PASSWORD=user_password
WP_USER_EMAIL=user@example.com
```

### 4. Installation & execution

⚠️ Most `make` commands that create or remove host folders require `sudo` unless your user has appropriate permissions.

```bash
# Build and start the project
sudo make all

# Stop the project
sudo make down

# Remove containers, images, volumes and host data
sudo make fclean
```

## Resources

- Docker documentation
- Nginx documentation
- MariaDB documentation

## AI Usage Disclosure

AI (Gemini & Copilot) was used as a collaborative assistant for:

  - Debugging & Refactoring: Optimizing Dockerfiles and layer efficiency.

  - Script Logic: Refining the setup.sh logic for service handshakes.

  - Documentation: Drafting and translating technical files for subject compliance.

## Authors

vjan-nie – 42 Curriculum
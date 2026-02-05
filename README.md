*This project has been created as part of the 42 curriculum by vjan-nie.*

# Inception

## Description

Inception is a project designed to simulate a full web service stack using Docker containers.  
The goal is to build a multi-service environment including:

- **MariaDB** as the database service  
- **WordPress** as the web application  
- **Nginx** as the web server / reverse proxy  

The project emphasizes **containerization best practices**, persistence, networking, and security configuration.  
It is designed to run inside a **Virtual Machine** for reproducibility and isolation from the host system.

### Main Design Choices

- **Docker Containers** instead of VM-only deployment: lightweight, reproducible, isolated environments  
- **Docker Compose** for orchestration of multiple services  
- **Volumes & Bind Mounts** for persistent data (`/data/mariadb`, `/data/wordpress`)  
- **Environment Variables** (database credentials, WordPress admin user)  
- **Self-signed SSL certificate** to enforce HTTPS in Nginx  
- **PHP-FPM** for efficient handling of PHP scripts  
- **FastCGI** between Nginx and WordPress for proper request handling  

#### Comparisons

| Concept                        | Choice in Project | Notes |
|--------------------------------|-----------------|-------|
| Virtual Machines vs Docker      | Docker          | Docker is lightweight, faster to deploy, easier to maintain than full VMs; VMs are heavier but provide full OS isolation. |
| Docker Network vs Host Network | Docker Network  | Isolates containers in a private network (`inception_network`), allows service-to-service communication without exposing ports unnecessarily. |
| Docker Volumes vs Bind Mounts   | Bind Mounts     | Data stored in host directories (`$HOME/data/...`) to persist across container rebuilds; ensures transparency and easy backup. |

---

## Instructions

### Prerequisites

- Docker & Docker Compose installed on your system  
- Linux-based environment (VM recommended)  

### Setup

1. **Clone the repository**:

```bash
git clone https://github.com/vjan-nie/Inception.git
cd inception
```

2. **Prepare persistent data folders** (Makefile handles this):

```bash
make setup
```

3. **Build and launch all services**:

```bash
make all
```

4. **Access WordPress**:
   - Open a browser and navigate to: https://vjan-nie.42.fr
   - Use the admin credentials set in the .env file

5. **Stop services**:

```bash
make down
```

6. **Clean everything** (optional):

```bash
make fclean
```

## Resources

- [Docker Documentation](https://docs.docker.com/) – Official guides and best practices
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MariaDB Documentation](https://mariadb.com/docs/)
- [WordPress Codex](https://developer.wordpress.org/)
- [Nginx Docs](https://nginx.org/en/docs/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)

## AI Usage

AI was used as an assistant for:

- Explaining Dockerfile and setup scripts
- Documenting best practices for environment variables, networking, volumes
- Creating this README and summarizing the design decisions

## Project Structure

```
srcs/
├── docker-compose.yml       # Orchestrates services: mariadb, wordpress, nginx
├── requirements/
│   ├── mariadb/
│   │   ├── Dockerfile
│   │   ├── conf/50-server.cnf
│   │   └── tools/setup.sh
│   ├── wordpress/
│   │   ├── Dockerfile
│   │   ├── conf/www.conf
│   │   └── tools/setup.sh
│   └── nginx/
│       ├── Dockerfile
│       └── conf/nginx.conf
Makefile                    # Commands for setup, build, and cleanup
.env                        # Environment variables for credentials
```

## Implementation Details

- **MariaDB**: Custom Dockerfile + init scripts, socket and PID properly configured, entrypoint ensures DB setup
- **WordPress**: PHP-FPM with FastCGI, waits for MariaDB before installing WordPress automatically
- **Nginx**: SSL enabled, reverse proxy to WordPress container

## Notes

- All containers run in foreground mode for PID1 compliance:
  - PHP-FPM: `--nodaemonize`
  - Nginx: `daemon off;`
- Persistence is handled through host bind mounts to `$HOME/data/...`
- Proper user permissions are enforced to allow WordPress to write files (www-data)
- The project is designed to be portable: rebuilding on another machine or VM reproduces the same environment

## Authors

- **vjan-nie** – 42 Curriculum

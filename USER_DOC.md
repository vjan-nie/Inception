# User Documentation

## System Requirements
- **OS**: Linux (Debian Bullseye recommended).
- **Permissions**: **Sudo/Root access is mandatory.** The Makefile creates directories in `/home/${USER}/data` and manages Docker system-wide.

## Step-by-Step Execution

### 1. Domain Setup
```bash
echo "127.0.0.1 vjan-nie.42.fr" | sudo tee -a /etc/hosts
```

### 2. Environment variables

Ensure a `.env` file exists in `srcs/` with your credentials (see `README.md` for a template).

### 3. Launching

From the project root run:

```bash
sudo make all
```

If you prefer not to use `sudo`, ensure your user can create the host `data` folders and manage Docker resources.

### 4. Verification

Open https://vjan-nie.42.fr in your browser. Expect a self-signed TLS warning (proceed manually if testing locally).

### Troubleshooting

- Permission denied during `make setup`: re-run with `sudo` or adjust host folder permissions.
- Port 443 busy: stop local Nginx/Apache or change host port mapping in `srcs/docker-compose.yml`.


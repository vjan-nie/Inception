# The Inception Stack, Explained

*From a 42 exercise to production infrastructure patterns.*

Inception looks like a toy: three containers serving a WordPress blog. But every constraint in the exercise maps to a real discipline that platform, DevOps, and SRE engineers practise daily. This guide walks the stack piece by piece — what it does **here**, the **concept** underneath, where you meet it **in production**, and the **best practice** to anchor to.

The architecture in one line: a browser reaches **NGINX** over TLS on 443; NGINX serves static files and forwards PHP to **WordPress/PHP-FPM**; WordPress persists state in **MariaDB**. The three run as isolated containers on a private network, with data on the host and secrets kept out of the image.

---

## 1. Containers instead of virtual machines

**Here.** Each service runs in its own Alpine container instead of one fat VM running everything.

**Concept.** A VM virtualizes hardware and ships a whole OS; a container shares the host kernel and isolates only a process tree, filesystem, and network namespace. The result is seconds-not-minutes startup and megabytes-not-gigabytes footprint.

**In production.** This is the foundation of modern delivery: the same image a developer builds locally runs unchanged in CI and in production, killing "works on my machine." Kubernetes, ECS, and Cloud Run all schedule containers, not VMs.

**Best practice.** One concern per container, so each can be scaled, restarted, and reasoned about independently. See the [Docker best-practices guide](https://docs.docker.com/build/building/best-practices/).

## 2. Images built from a pinned source

**Here.** Every image is built from a hand-written Dockerfile on `alpine:3.22` — never pulled pre-built, never tagged `latest`.

**Concept.** A pinned base tag makes a build *reproducible*: the same Dockerfile yields the same image today and in six months. `latest` is a moving target that silently changes under you.

**In production.** This is the entry point to supply-chain security: pinned (ideally digest-locked) bases, scanned layers, and minimal images shrink both the attack surface and the "why did the build break overnight" class of incidents. Alpine is popular precisely because it is tiny.

**Best practice.** Pin versions, keep images minimal, order layers so the expensive steps cache. Treat the Dockerfile as the single source of how the image is assembled.

## 3. PID 1 and honest process management

**Here.** NGINX runs with `daemon off;`, MariaDB ends in `exec mariadbd`, PHP-FPM runs with `-F`. No `tail -f`, no `sleep infinity`.

**Concept.** A container *is* its main process (PID 1). If that process daemonizes into the background and PID 1 becomes a shell loop, the container can't receive `SIGTERM` cleanly — so it gets killed hard, risking data corruption and slow shutdowns. Running the real service in the foreground as PID 1 lets the orchestrator stop it gracefully.

**In production.** Graceful shutdown is what lets a load balancer drain connections during a rolling deploy. The PID 1 "zombie reaping" problem is common enough that tools like `tini` and `dumb-init` exist to solve it.

**Best practice.** `exec` the real daemon as PID 1; never wrap it in a busy-wait. This is the difference between a container and a VM you happen to keep alive.

## 4. The entrypoint pattern and readiness

**Here.** MariaDB's entrypoint initialises the database on first run via a temporary `--skip-networking` bootstrap server, then `exec`s the production daemon. WordPress's entrypoint waits for MariaDB to answer an authenticated `mariadb-admin ping` before installing.

**Concept.** Containers start in parallel, so "started" never means "ready." Entrypoints separate *first-run provisioning* (create the DB, install WordPress) from *every-run startup*, and a readiness wait prevents the classic race where the app connects before the database accepts queries.

**In production.** Kubernetes formalises exactly this with **init containers** (one-time setup), **liveness probes** (is it alive?), and **readiness probes** (can it take traffic?). The hand-rolled `ping` loop here is the same idea in miniature.

**Best practice.** Make startup idempotent and gate dependents on real readiness, not on a fixed `sleep`.

## 5. A private network with one front door

**Here.** The three containers share a private bridge network (`inception_network`) and address each other by service name (`wordpress`, `mariadb`). Only NGINX publishes a port; MariaDB and PHP-FPM are unreachable from outside.

**Concept.** Container networking gives each service a name-resolvable address on an isolated segment. Exposing a single ingress and keeping everything else internal is the principle of *least exposure*.

**In production.** This is service discovery and network segmentation — the model behind Kubernetes Services and DNS, service meshes (Istio, Linkerd), and the "one ingress controller, private backends" topology that virtually every web platform uses. (At the VM layer, this project adds a **host-only adapter** so the host browser can reach the site at a fixed private address without exposing it to the wider network — the same instinct applied one level up.)

**Best practice.** Default-deny exposure; publish only the edge. `network: host` and container links are avoided for exactly this reason.

## 6. TLS terminated at the edge

**Here.** NGINX is the sole entry point, listening on 443 with TLS 1.2/1.3 only and a certificate for the site's domain.

**Concept.** *TLS termination* means encryption is handled at the edge proxy, so backend services speak plain protocols on the trusted internal network. Restricting to modern TLS versions drops known-weak protocols.

**In production.** Edge termination is universal: an ALB, NGINX, Envoy, or a CDN like Cloudflare terminates TLS, and managed certificates (Let's Encrypt / ACM) replace the self-signed cert used here for local testing.

**Best practice.** Modern protocols only, sane cipher suites, automated certificate renewal. Mozilla's [SSL Configuration Generator](https://ssl-config.mozilla.org/) is the standard reference.

## 7. Web server and application server, split over FastCGI

**Here.** NGINX serves static files directly and forwards `.php` requests to PHP-FPM on port 9000 via FastCGI.

**Concept.** The web server (fast at I/O and static content) and the application runtime (executes code) are different jobs, so they are separate processes connected by a protocol. NGINX doesn't run PHP; it hands dynamic requests to a process pool that does.

**In production.** This split is everywhere: NGINX/Apache in front of PHP-FPM, or a reverse proxy in front of Gunicorn/Puma/Node workers. It lets you scale the app tier independently and keep the edge lean.

**Best practice.** Keep the proxy and the runtime as distinct, independently tunable tiers (worker counts, timeouts, limits).

## 8. State lives outside the container

**Here.** Two bind mounts map container data to the host: the database to `/home/<user>/data/mariadb`, the WordPress files to `/home/<user>/data/wordpress`.

**Concept.** Containers are ephemeral and should be *stateless* — destroy and recreate them freely. Anything that must survive (databases, uploads) lives in a volume, decoupled from the container's lifecycle. Bind mounts pin data to a known host path (handy for inspection and grading); named volumes let the engine manage storage (better for portability).

**In production.** The same line separates stateless app pods from managed stateful storage: persistent volumes, RDS, S3. Knowing what is safe to throw away — and what must be backed up — is core operational judgment.

**Best practice.** Treat containers as cattle, not pets; keep state in explicit, backed-up volumes. Bind mounts for local/dev visibility, managed volumes for portable deployments.

## 9. Configuration in the environment, secrets in secrets

**Here.** Non-sensitive settings (domain, database and user names, the admin username) live in `.env`; passwords are **Docker secrets** — files mounted read-only at `/run/secrets/` and read at runtime, never baked into the image or the environment, never committed to Git.

**Concept.** Configuration should be external to the build so the same image runs in any environment. Secrets are configuration with teeth: environment variables leak through `docker inspect`, `/proc/<pid>/environ`, and child processes, whereas a mounted secret stays out of the image layers, the process environment, and version control.

**In production.** This is the boundary between plain config and a secrets manager: HashiCorp Vault, AWS Secrets Manager, or Kubernetes Secrets, with rotation and access policies on top. Leaked credentials in a repo are one of the most common real-world breaches.

**Best practice.** Externalise config; never hardcode or commit secrets. The [Twelve-Factor App](https://12factor.net/config) is the canonical statement of the principle.

## 10. Declarative orchestration and reproducible builds

**Here.** `docker-compose.yml` declares the services, network, volumes, and secrets; a `Makefile` builds and runs the whole stack with one command and tears it down cleanly.

**Concept.** The desired state of the system is written down and version-controlled, not assembled by hand. `make` is the reproducible entry point; Compose is the declarative description the engine reconciles.

**In production.** This is Infrastructure as Code: Compose for a single host, Kubernetes manifests or Helm for clusters, Terraform for the cloud underneath. The value is the same — the system is described in files anyone can read, review, and rebuild from scratch.

**Best practice.** One command to stand the whole thing up; the repository is the source of truth for *what* runs and *how*.

## 11. The machine itself is code, too

**Here.** A companion repository provisions the host VM unattended — an automated Debian install (preseed) plus a first-boot script that installs Docker and tooling and configures networking, so a fresh machine comes up ready to run the stack.

**Concept.** *Immutable / reproducible infrastructure*: you don't hand-configure a server and hope to remember the steps — you describe it and rebuild it identically on demand.

**In production.** This is the world of cloud-init, Packer "golden images," and Ansible. The preseed + first-boot pair here is a small, honest version of how fleets of servers are born already configured.

**Best practice.** No snowflake servers. Provisioning is scripted, idempotent, and stored in version control.

---

## What this demonstrates

Stripped of the WordPress wrapper, this project is a complete, deliberately small production web platform — and building it touches the competencies that define infrastructure work:

- **Containerization & image hygiene** — isolated services, pinned reproducible builds, minimal attack surface.
- **Process & lifecycle correctness** — PID 1, graceful shutdown, readiness gating.
- **Networking & edge** — private service networks, single TLS ingress, least exposure.
- **Stateful data** — what persists, where it lives, what gets backed up.
- **Configuration & secrets management** — externalised config, secrets kept out of images and Git.
- **Infrastructure as Code** — declarative orchestration and reproducible, scripted provisioning from the VM up.

Every one of these scales directly into Docker Compose → Kubernetes, self-signed → managed certificates, `.env`/secrets files → a secrets manager, and a preseeded VM → cloud-init and golden images. The exercise is small on purpose; the patterns are not.

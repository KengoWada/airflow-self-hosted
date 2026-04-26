# Airflow Deployment with Docker Compose

This repository runs Apache Airflow with supporting databases/object storage and a full monitoring stack using Docker Compose.

## Stack Overview

- `docker-compose.dbs.yaml`: PostgreSQL, Redis, Garage, Garage Web UI
- `docker-compose.monitoring.yaml`: StatsD Exporter, Prometheus, Loki, Alloy, Grafana
- `docker-compose.airflow.yaml`: Airflow services

## Quick Start (Recommended)

Follow these steps in order after cloning the repository.

### 1. Prepare environment files

Copy the template env directory and fill all values marked like `<missing-data>`.

```bash
cp -r env_example env
```

Before moving on, generate secure values for Garage and Airflow using the section below, then paste them into the related files in `env/`.

Update the files in `env/` before continuing:

- `.postgres.env`
- `.airflow.env`
- `.airflow.jwt.env`
- `.garage.env`
- `.garage.webui.env`

## Generate Secure Secrets

Use these commands to generate strong secrets for Garage and Airflow.

### Airflow JWT Secret, Fernet Key, and Webserver Secret Key

Generate the values:

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"  # JWT secret
python3 -c "from base64 import urlsafe_b64encode; from os import urandom; print(urlsafe_b64encode(urandom(32)).decode())"  # Fernet key
python3 -c "import secrets; print(secrets.token_hex(32))"  # Webserver secret key
```

Set them in these files:

`env/.airflow.jwt.env`

```env
AIRFLOW__API_AUTH__JWT_SECRET=<paste-jwt-secret>
```

`env/.airflow.env`

```env
AIRFLOW__CORE__FERNET_KEY=<paste-fernet-key>
AIRFLOW__WEBSERVER__SECRET_KEY=<paste-webserver-secret-key>
```

### Garage RPC Secret and Admin Token

Generate the values:

```bash
python3 -c "import secrets; print(secrets.token_hex(32))" # RPC secret
python3 -c "import base64, secrets; print(base64.b64encode(secrets.token_bytes(32)).decode())" # Admin token
```

Set them in `env/.garage.env`:

```env
GARAGE_RPC_SECRET=<paste-rpc-secret>
GARAGE_ADMIN_TOKEN=<paste-admin-token>
```

Also set the same values in `garage/garage.toml` because Garage Web UI reads from this file and may not recognize env vars for these fields:

```toml
rpc_secret = "<missing-data>"

[admin]
admin_token = "<missing-data>"
```

Keep only placeholders in the tracked `garage/garage.toml` file. Do not commit real secrets to Git.

### Garage Web UI Password Hash

Generate a bcrypt hash for the Web UI credentials:

```bash
htpasswd -nbBC 10 "<username>" "<strong-password>"
```

This prints a value like:

```text
<username>:$2y$10$...
```

Set it in `env/.garage.webui.env`:

```env
AUTH_USER_PASS='<username>:$2y$10$...'
```

Notes:

- Keep the single quotes around `AUTH_USER_PASS`.
- Use a long, unique password.
- Do not commit real secrets to version control.

### 2. Start databases and object storage

```bash
docker network create airflow-network || true  # Create a Docker network for the stack (if not already created)
make up app=dbs
```

### 3. Configure Garage from the Web UI (no CLI required)

Open `http://localhost:3909`.

Use the credentials from `env/.garage.webui.env` and configure Garage:

1. In `Cluster`, assign the node and apply the layout.
2. In `Keys`, create a key for Airflow and save the generated key ID and secret.
3. In `Buckets`, create a bucket named `airflow`.
4. Grant read/write/owner access on bucket `airflow` to the Airflow key.
5. Set `AIRFLOW_CONN_GARAGE_S3` in `env/.airflow.env` using that key ID and secret.

### 4. Start monitoring

```bash
make up app=monitoring
```

### 5. Start Airflow

```bash
make up app=airflow
```

Airflow API server should be available on `http://localhost:8080`.
Grafana should be available on `http://localhost:3000`.

## Makefile Shortcuts

This repository includes a `Makefile` to shorten long Docker Compose commands.

- Start a stack: `make up app=<dbs|monitoring|airflow>`
- Start with build: `make buildup app=<dbs|monitoring|airflow>`
- Stop a stack: `make down app=<dbs|monitoring|airflow>`
- Stop and remove volumes: `make kill app=<dbs|monitoring|airflow>`

You can check the `Makefile` to see the exact underlying commands.

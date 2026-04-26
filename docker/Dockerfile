# ===========================================
# ============== Builder Image ==============
# ===========================================
FROM python:3.13 AS builder

# Install build dependencies for Airflow DB drivers without DB CLI clients.
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY ./constraints.txt /tmp/constraints.txt

# Install Airflow with the necessary extras for DB drivers.
RUN pip install --no-cache-dir \
    "apache-airflow[postgres, amazon, celery, common.compat, common.io, fab, git, http, redis, smtp, statsd]==3.2.1" \
    --constraint /tmp/constraints.txt

COPY ./requirements.txt /tmp/requirements.txt

# Install additional dependencies from requirements.txt, if any.
RUN pip install --no-cache-dir \
    -r /tmp/requirements.txt \
    --constraint /tmp/constraints.txt

# ===========================================
# ============== Runtime Image ==============
# ===========================================
FROM python:3.13-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV AIRFLOW_HOME=/opt/airflow
ENV AIRFLOW__CORE__LOAD_EXAMPLES=False

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --system airflow \
    && useradd --system --gid airflow --home-dir /opt/airflow --create-home airflow \
    && mkdir -p /opt/airflow/{dags,plugins,logs,config} \
    && chown -R airflow:airflow /opt/airflow \
    && chmod -R 755 /opt/airflow

COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

WORKDIR /opt/airflow

USER airflow

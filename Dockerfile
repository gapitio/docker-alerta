FROM python:3.12-slim-trixie AS builder
WORKDIR /

ARG BUILD_DATE
ARG RELEASE
ARG VERSION

ENV SERVER_VERSION=${RELEASE}
ENV CLIENT_VERSION=4.0.0
ENV WEBUI_VERSION=${RELEASE}

ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    gnupg2 \
    libldap2-dev \
    libpq-dev \
    libsasl2-dev \
    postgresql-client \
    python3-dev \
    supervisor \
    libpcre2-dev \ 
    libpcre2-8-0 \
    ca-certificates \
    xmlsec1 && \
    apt-get -y clean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*


COPY requirements*.txt /app/

# hadolint ignore=DL3013
RUN pip install --no-cache-dir pip virtualenv && \
    python3.12 -m venv /venv && \
    /venv/bin/pip install --no-cache-dir --upgrade setuptools && \
    /venv/bin/pip install --no-cache-dir --requirement /app/requirements.txt && \
    /venv/bin/pip install --no-cache-dir --requirement /app/requirements-docker.txt && \
    /venv/bin/pip install --no-cache-dir jinja2

ENV PATH=$PATH:/venv/bin

#download and install alerta client
ADD https://github.com/gapitio/python-alerta-client/releases/download/v${CLIENT_VERSION}/alerta-client.tar.gz /tmp/client/client.tar.gz
RUN tar zxvf /tmp/client/client.tar.gz -C /tmp/client/ && \
    find /tmp/client/dist -name "*-py2.py3-none-any.whl" -print0 | xargs -0 -I{} /venv/bin/pip install {}

#download and install alerta server/backend
ADD https://github.com/gapitio/alerta/releases/download/${SERVER_VERSION}/alerta-api.tar.gz /tmp/backend/alerta.tar.gz
RUN tar zxvf /tmp/backend/alerta.tar.gz -C /tmp/backend && \
    find /tmp/backend/dist -name "*-py2.py3-none-any.whl" -print0 | xargs -0 -I{} /venv/bin/pip install {}


#download and install alerta server/backend
ADD https://github.com/gapitio/alerta-webui/releases/download/${WEBUI_VERSION}/alerta-webui.tar.gz /tmp/webui.tar.gz
RUN tar zxvf /tmp/webui.tar.gz -C /tmp && \
    mv /tmp/dist /web


FROM python:3.12-slim-trixie AS runtime
WORKDIR /

COPY --from=builder /venv /venv
COPY --from=builder /web /web
COPY --from=builder /app /app

ARG RELEASE
ENV GAPIT_VERSION=${RELEASE}

ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV PATH=$PATH:/venv/bin

ENV NGINX_WORKER_PROCESSES=1
ENV NGINX_WORKER_CONNECTIONS=1024

ENV UWSGI_PROCESSES=5
ENV UWSGI_LISTEN=100
ENV UWSGI_BUFFER_SIZE=8192
ENV UWSGI_MAX_WORKER_LIFETIME=30
ENV UWSGI_WORKER_LIFETIME_DELTA=3
ENV FRONTEND_BASE_URL=/

ENV HEARTBEAT_SEVERITY=major

ENV ALERTA_SVR_CONF_FILE=/app/alertad.conf
ENV ALERTA_CONF_FILE=/app/alerta.conf
ENV ALERTA_WEB_CONF_FILE=/web/config.json

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    gnupg2 \
    libpq-dev \
    supervisor \
    ca-certificates \
    xmlsec1 \
    nginx && \
    apt-get -y clean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

COPY config/templates/app/ /app
COPY config/templates/web/ /web

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# user and permissions
RUN chgrp -R 0 /app /venv /web && \
    chmod -R g=u /app /venv /web && \
    useradd -u 1001 -g 0 -d /app alerta

USER 1001

# entry point
ENV INIT_LOG=false
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 8080 1717
CMD ["supervisord", "-c", "/app/supervisord.conf"]
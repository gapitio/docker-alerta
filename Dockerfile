FROM python:3.9-slim-buster as production-stage
WORKDIR /


ENV PYTHONUNBUFFERED 1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1

ARG BUILD_NUMBER
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

ENV SERVER_VERSION=1.5.0
ENV CLIENT_VERSION=8.5.0
ENV WEBUI_VERSION=1.5.0

ENV NGINX_WORKER_PROCESSES=1
ENV NGINX_WORKER_CONNECTIONS=1024

ENV UWSGI_PROCESSES=5
ENV UWSGI_LISTEN=100
ENV UWSGI_BUFFER_SIZE=8192
ENV UWSGI_MAX_WORKER_LIFETIME=30
ENV UWSGI_WORKER_LIFETIME_DELTA=3

ENV HEARTBEAT_SEVERITY=major
ENV HK_EXPIRED_DELETE_HRS=2
ENV HK_INFO_DELETE_HRS=12

LABEL org.opencontainers.image.description="Alerta API (prod)" \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.url="https://github.com/alerta/alerta/pkgs/container/alerta-api" \
    org.opencontainers.image.source="https://github.com/alerta/alerta" \
    org.opencontainers.image.version=$RELEASE \
    org.opencontainers.image.revision=$VERSION \
    org.opencontainers.image.licenses=Apache-2.0

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
    libpcre3 \
    libpcre3-dev \
    ca-certificates \
    xmlsec1 && \
    apt-get -y clean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - && \
    echo "deb https://nginx.org/packages/debian/ buster nginx" | tee /etc/apt/sources.list.d/nginx.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    nginx && \
    apt-get -y clean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL3008
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add - && \
    echo "deb https://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    mongodb-org-shell && \
    apt-get -y clean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

COPY requirements*.txt /app/

# hadolint ignore=DL3013
RUN pip install --no-cache-dir pip virtualenv jinja2 && \
    python3 -m venv /venv && \
    /venv/bin/pip install --no-cache-dir --upgrade setuptools && \
    /venv/bin/pip install --no-cache-dir --requirement /app/requirements.txt && \
    /venv/bin/pip install --no-cache-dir --requirement /app/requirements-docker.txt
ENV PATH $PATH:/venv/bin

ADD https://github.com/gapitio/python-alerta-client/archive/refs/heads/gapit.tar.gz /tmp/client/client.tar.gz
RUN tar zxvf /tmp/client/client.tar.gz -C /tmp/client/ && \
    /venv/bin/pip install /tmp/client/python-alerta-client-gapit/.
ADD https://github.com/gapitio/alerta/releases/download/v${SERVER_VERSION}/alerta-api.tar.gz /tmp/backend/alerta.tar.gz
RUN tar zxvf /tmp/backend/alerta.tar.gz -C /tmp/backend && \
    find /tmp/backend/dist -name "*-py2.py3-none-any.whl" -print0 | xargs -0 -I{} /venv/bin/pip install {}
COPY install-plugins.sh /app/install-plugins.sh
COPY plugins.txt /app/plugins.txt
RUN /app/install-plugins.sh

ENV ALERTA_SVR_CONF_FILE /app/alertad.conf
ENV ALERTA_CONF_FILE /app/alerta.conf

ADD https://github.com/gapitio/alerta-webui/releases/download/v${WEBUI_VERSION}/alerta-webui.tar.gz /tmp/webui.tar.gz
RUN tar zxvf /tmp/webui.tar.gz -C /tmp && \
    mv /tmp/dist /web

ENV ALERTA_SVR_CONF_FILE /app/alertad.conf
ENV ALERTA_CONF_FILE /app/alerta.conf
ENV ALERTA_WEB_CONF_FILE /web/config.json

COPY config/templates/app/ /app
COPY config/templates/web/ /web

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

RUN chgrp -R 0 /app /venv /web && \
    chmod -R g=u /app /venv /web && \
    useradd -u 1001 -g 0 -d /app alerta

USER 1001

COPY docker-entrypoint.sh /usr/local/bin/

ENV INIT_LOG false

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 8080 1717
CMD ["supervisord", "-c", "/app/supervisord.conf"]

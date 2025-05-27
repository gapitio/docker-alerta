#!/bin/bash

JINJA2="import os, sys, jinja2; sys.stdout.write(jinja2.Template(sys.stdin.read()).render(env=os.environ)+'\n')"

ALERTA_CONF_FILE=${ALERTA_CONF_FILE:-/app/alerta.conf}
ALERTA_SVR_CONF_FILE=${ALERTA_SVR_CONF_FILE:-/app/alertad.conf}
ALERTA_WEB_CONF_FILE=${ALERTA_WEB_CONF_FILE:-/web/config.json}
NGINX_CONF_FILE=/app/nginx.conf
UWSGI_CONF_FILE=/app/uwsgi.ini
SUPERVISORD_CONF_FILE=/app/supervisord.conf

if [ $INIT_LOG = true ]; then set -ex; else set -e; fi

if [ $INIT_LOG = true ]; then env | sort; fi

ADMIN_USER=${ADMIN_USERS%%,*}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-alerta}
MAXAGE=${ADMIN_KEY_MAXAGE:-315360000}  # default=10 years

# Generate minimal server config, if not supplied
if [ ! -f "${ALERTA_SVR_CONF_FILE}" ]; then
  if [ $INIT_LOG = true ]; then echo "# Create server configuration file."; fi
  export SECRET_KEY=${SECRET_KEY:-$(< /dev/urandom tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= | head -c 32)}
  python3 -c "${JINJA2}" < ${ALERTA_SVR_CONF_FILE}.j2 >${ALERTA_SVR_CONF_FILE}
fi

# Init admin users and API keys
if [ -n "${ADMIN_USERS}" ]; then
  if [ $INIT_LOG = true ]; then echo "# Create admin users."; fi
  if [ $INIT_LOG = true ]; then alertad user --all --password "${ADMIN_PASSWORD}" || true; else alertad user --all --password "${ADMIN_PASSWORD}" > /dev/null || true; fi
  if [ $INIT_LOG = true ]; then echo "# Create admin API keys."; fi
  if [ $INIT_LOG = true ]; then alertad key --all; else alertad key --all > /dev/null; fi

  # Create user-defined API key, if required
  if [ -n "${ADMIN_KEY}" ]; then
    if [ $INIT_LOG = true ]; then echo "# Create user-defined admin API key."; fi
    alertad key --username "${ADMIN_USER}" --key "${ADMIN_KEY}" --duration "${MAXAGE}"
  fi
fi

# Generate minimal client config, if not supplied
if [ ! -f "${ALERTA_CONF_FILE}" ]; then
  # Add API key to client config, if required
  if [ "${AUTH_REQUIRED,,}" == "true" ]; then
    if [ $INIT_LOG = true ]; then echo "# Auth enabled; add admin API key to client configuration."; fi
    HOUSEKEEPING_SCOPES="--scope read --scope write:alerts --scope admin:management --scope write:notification_rules --scope delete:alerts"
    if grep -qE 'CUSTOMER_VIEWS.*=.*True' ${ALERTA_SVR_CONF_FILE};then
      HOUSEKEEPING_SCOPES="--scope admin:alerts ${HOUSEKEEPING_SCOPES}"
    fi
    export API_KEY=$(alertad key \
    --username "${ADMIN_USER}" \
    ${HOUSEKEEPING_SCOPES} \
    --duration "${MAXAGE}" \
    --text "Housekeeping")
  fi
  if [ $INIT_LOG = true ]; then echo "# Create client configuration file."; fi
  python3 -c "${JINJA2}" < ${ALERTA_CONF_FILE}.j2 >${ALERTA_CONF_FILE}
fi

# Generate supervisord config, if not supplied
if [ ! -f "${SUPERVISORD_CONF_FILE}" ]; then
  if [ $INIT_LOG = true ]; then echo "# Create supervisord configuration file."; fi
  python3 -c "${JINJA2}" < ${SUPERVISORD_CONF_FILE}.j2 >${SUPERVISORD_CONF_FILE}
fi

# Generate nginx config, if not supplied.
if [ ! -f "${NGINX_CONF_FILE}" ]; then
  if [ $INIT_LOG = true ]; then echo "# Create nginx configuration file."; fi
  python3 -c "${JINJA2}" < ${NGINX_CONF_FILE}.j2 >${NGINX_CONF_FILE}
fi
nginx -t -c ${NGINX_CONF_FILE}

# Generate uWSGI config, if not supplied.
if [ ! -f "${UWSGI_CONF_FILE}" ]; then
  if [ $INIT_LOG = true ]; then echo "# Create uWSGI configuration file."; fi
  python3 -c "${JINJA2}" < ${UWSGI_CONF_FILE}.j2 >${UWSGI_CONF_FILE}
fi

# Generate web config, if not supplied.
if [ ! -f "${ALERTA_WEB_CONF_FILE}" ]; then
  if [ $INIT_LOG = true ]; then echo "# Create web configuration file."; fi
  python3 -c "${JINJA2}" < ${ALERTA_WEB_CONF_FILE}.j2 >${ALERTA_WEB_CONF_FILE}
fi

if [ $INIT_LOG = true ]; then 
  echo
  echo '# Checking versions.'
  echo Alerta Server ${SERVER_VERSION}
  echo Alerta Client ${CLIENT_VERSION}
  echo Alerta WebUI  ${WEBUI_VERSION}

  nginx -v
  echo uwsgi $(uwsgi --version)
  psql --version
  python3 --version
  /venv/bin/pip list

  echo
  echo 'Alerta init process complete; ready for start up.'
  echo
fi
exec "$@"

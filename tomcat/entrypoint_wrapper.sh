#!/bin/bash
set -e

# Create a named pipe that all access logs will be redirected to
ACCESS_LOG_DIR="${ACCESS_LOG_DIR:-${CATALINA_HOME}/logs}"
ACCESS_LOG_NAME="${ACCESS_LOG_NAME:-accesslogpipe}"
ACCESS_LOG_OWNER="${TOMCAT_USER_ID:-1000}"
ACCESS_LOG_PATH="${ACCESS_LOG_DIR}/${ACCESS_LOG_NAME}"
if [[ -e "${ACCESS_LOG_PATH}" ]] || [[ -p "${ACCESS_LOG_PATH}" ]]; then
  rm "${ACCESS_LOG_PATH}"
fi
mkdir -p "${ACCESS_LOG_DIR}"
mkfifo -m 600 "${ACCESS_LOG_PATH}"
chown "${ACCESS_LOG_OWNER}" "${ACCESS_LOG_PATH}"

ACCESS_LOG_TARGET="/dev/null"
if [[ "${ACCESS_LOGGING_ENABLED:-true}" == "true" ]]; then
  ACCESS_LOG_TARGET="/dev/stdout"
fi
cat < "${ACCESS_LOG_PATH}" &>> "${ACCESS_LOG_TARGET}" &

# Ensure all expected runtime environment variables have been defined
if [ -r "$CATALINA_HOME/bin/javaopts.sh" ]; then
  . "$CATALINA_HOME/bin/javaopts.sh"
else
    export JAVA_OPTS="-server -Xms${TOMCAT_XMS_SIZE:-1G} -Xmx${TOMCAT_XMX_SIZE:-1G} -XX:+HeapDumpOnOutOfMemoryError -Djava.awt.headless=true"
fi
echo "JAVA_OPTS=\"${JAVA_OPTS}\""
echo

# Check if we want to switch to log4J for tomcat server logging
LOG4J_DIR="${LOG4J_DIR:-/usr/share/java/log4j}"
LOG4J_LOGGING_CONFIG="${LOG4J_LOGGING_CONFIG:-${CATALINA_HOME}/conf/log4j2.xml}"
if [[ -d "${LOG4J_DIR}" ]] && [[ -f "${LOG4J_LOGGING_CONFIG}" ]]; then
  export LOGGING_MANAGER="-Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager"
  export CATALINA_OPTS="${CATALINA_OPTS} ${LOGGING_MANAGER} -Dlog4j.configurationFile='${LOG4J_LOGGING_CONFIG}' -Dlog4j2.configurationFile='${LOG4J_LOGGING_CONFIG}'"
fi

# Ensure all our access-logging, connector and cors environment variables are passed to the JVM
CATALINA_OPTS="${CATALINA_OPTS} -DACCESS_LOG_DIR='${ACCESS_LOG_DIR}'"
CATALINA_OPTS="${CATALINA_OPTS} -DACCESS_LOG_NAME='${ACCESS_LOG_NAME}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_COMPRESSIBLE_MIME_TYPE='${CONNECTOR_COMPRESSIBLE_MIME_TYPE:-text/html,text/xml,text/plain,text/css,text/javascript,application/javascript,application/json,application/octet-stream,application/xml}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_COMPRESSION='${CONNECTOR_COMPRESSION:-on}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_COMPRESSION_MIN_SIZE='${CONNECTOR_COMPRESSION_MIN_SIZE:-2048}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_CONNECTION_TIMEOUT='${CONNECTOR_CONNECTION_TIMEOUT:-20000}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_MAX_THREADS='${CONNECTOR_MAX_THREADS:-50}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_PROXY_NAME='${CONNECTOR_PROXY_NAME:-localhost}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_PROXY_PORT='${CONNECTOR_PROXY_PORT:-443}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_PROXY_SCHEME='${CONNECTOR_PROXY_SCHEME:-https}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_PROXY_SECURE='${CONNECTOR_PROXY_SECURE:-true}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_RELAXED_PATH_CHARS='${CONNECTOR_RELAXED_PATH_CHARS:-}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_RELAXED_QUERY_CHARS='${CONNECTOR_RELAXED_QUERY_CHARS:-}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCONNECTOR_SERVER='${CONNECTOR_SERVER:-Apache}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCORS_ALLOWED_ORIGINS='${CORS_ALLOWED_ORIGINS:-*}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCORS_ALLOWED_METHODS='${CORS_ALLOWED_METHODS:-GET,POST,HEAD,OPTIONS,PUT}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCORS_ALLOWED_HEADERS='${CORS_ALLOWED_HEADERS:-Authorization,Origin,Accept,X-Requested-With,Content-Type,Access-Control-Request-Method,Access-Control-Request-Headers}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCORS_EXPOSED_HEADERS='${CORS_EXPOSED_HEADERS:-}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCORS_PREFLIGHT_MAXAGE='${CORS_PREFLIGHT_MAXAGE:-10}'"
CATALINA_OPTS="${CATALINA_OPTS} -DCORS_SUPPORT_CREDENTIALS='${CORS_SUPPORT_CREDENTIALS:-false}'"
CATALINA_OPTS="${CATALINA_OPTS} -DREMOTE_IP_TRUSTED_PROXIES='${REMOTE_IP_TRUSTED_PROXIES:-}'"
export CATALINA_OPTS
echo "CATALINA_OPTS=\"${CATALINA_OPTS}\""
echo


# Pass entrypoint execution on to the default/wrapped entrypoint script
#exec /entrypoint.sh $@
. /entrypoint.sh
#!/bin/bash
set -e
if [ -r "$CATALINA_HOME/bin/javaopts.sh" ]; then
  . "$CATALINA_HOME/bin/javaopts.sh"
else
    export JAVA_OPTS="-server -Xms${TOMCAT_XMS_SIZE:-1G} -Xmx${TOMCAT_XMX_SIZE:-1G} -XX:+HeapDumpOnOutOfMemoryError -Djava.awt.headless=true"
fi
echo "JAVA_OPTS=\"${JAVA_OPTS}\""
echo

# Create a named pipe for the access logs, and redirect anything that comes to it to stdout.
# This is in lieu of making the logs write to /dev/stdout (/proc/self/fd/1), which doesn't
# work for non-root users in docker
# See: https://github.com/moby/moby/issues/6880#issuecomment-170214851
if [[ ! -p /tmp/accesslogpipe ]]; then
    mkfifo -m 600 /tmp/accesslogpipe
fi
chown ${TOMCAT_USER_ID}:${TOMCAT_GROUP_ID} /tmp/accesslogpipe
cat < /tmp/accesslogpipe 2>&1 &

# Ask Tomcat's JVM to use the environmenent-defined logger(s)
export CLASSPATH="${CATALINA_HOME}/bin/bootstrap.jar:${CATALINA_HOME}/bin/tomcat-juli.jar:${LOG_JAR_DIR}/*"
#export CLASSPATH="${CATALINA_HOME}/bin/bootstrap.jar:${CATALINA_HOME}/bin/tomcat-juli.jar:${LOG_JAR_DIR}/log4j-jul-${LOG4J_VERSION}.jar:${LOG_JAR_DIR}/log4j-api-${LOG4J_VERSION}.jar:${LOG_JAR_DIR}/log4j-core-${LOG4J_VERSION}.jar:${LOG_JAR_DIR}/slf4j-api-${SLF4J_VERSION}.jar"

CATALINA_OPTS="${CATALINA_OPTS} -Dlog4j.configurationFile='${CATALINA_HOME}/conf/log4j2.xml'"
CATALINA_OPTS="${CATALINA_OPTS} -Djava.util.logging.manager='org.apache.logging.log4j.jul.LogManager'"

# Tomcat connector environment variable settings
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.compressibleMimeType='${CONNECTOR_COMPRESSIBLE_MIME_TYPE}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.compression='${CONNECTOR_COMPRESSION}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.compressionMinSize='${CONNECTOR_COMPRESSION_MIN_SIZE}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.connectionTimeout='${CONNECTOR_CONNECTION_TIMEOUT}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.maxThreads='${CONNECTOR_MAX_THREADS}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.protocol='${CONNECTOR_PROTOCOL}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.proxyName='${CONNECTOR_PROXYNAME}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.proxyPort='${CONNECTOR_PROXYPORT}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.proxyScheme='${CONNECTOR_PROXYSCHEME}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.proxySecure='${CONNECTOR_PROXYSECURE}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.server='${CONNECTOR_SERVER}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dconnector.trustedProxies='${CONNECTOR_TRUSTED_PROXIES}'"

# Tomcat CORS environment variable settings
CATALINA_OPTS="${CATALINA_OPTS} -Dcors.allowed.origins='${CORS_ALLOWED_ORIGINS}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dcors.allowed.methods='${CORS_ALLOWED_METHODS}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dcors.allowed.headers='${CORS_ALLOWED_HEADERS}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dcors.exposed.headers='${CORS_EXPOSED_HEADERS}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dcors.preflight.maxage='${CORS_PREFLIGHT_MAXAGE}'"
CATALINA_OPTS="${CATALINA_OPTS} -Dcors.support.credentials='${CORS_SUPPORT_CREDENTIALS}'"

# Dump all the options to stdout for debugging purposes.
export CATALINA_OPTS
echo "CATALINA_OPTS=\"${CATALINA_OPTS}\""
echo

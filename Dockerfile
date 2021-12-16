# ALlow the base-image to be selected at build time.
# The default is a security-hardened version of the official tomcat image.
ARG BASE_IMAGE="unidata/tomcat-docker:8.5"
FROM $BASE_IMAGE

# Record the actual base image used from the FROM command in the build output.
ARG BASE_IMAGE=$BASE_IMAGE
RUN echo "Base Image: ${BASE_IMAGE}"

# Run updates for all OS packages in case the base image is old
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Keep all the additional logging jars together
ENV LOG_JAR_DIR=${CATALINA_HOME}/lib/log4j
RUN mkdir -p "${LOG_JAR_DIR}"

# Download and install *specific* versions of Log4j2 and SLF4J binaries.
ARG LOG4J_VERSION
ENV LOG4J_VERSION=${LOG4J_VERSION:-2.15.0}
ENV LOG4J_JARS="log4j-core log4j-api log4j-1.2-api log4j-jul log4j-slf4j-impl"
ADD http://archive.apache.org/dist/logging/log4j/${LOG4J_VERSION}/apache-log4j-${LOG4J_VERSION}-bin.tar.gz  /tmp/
RUN tar -xzf /tmp/apache-log4j-${LOG4J_VERSION}-bin.tar.gz -C /tmp/; \
    mkdir -p ${LOG_JAR_DIR}; \
    for LOG4J_JAR in $LOG4J_JARS; do \
        cp /tmp/apache-log4j-${LOG4J_VERSION}-bin/${LOG4J_JAR}-${LOG4J_VERSION}.jar ${LOG_JAR_DIR}/; \
    done; \
    rm -r /tmp/apache-log4j-${LOG4J_VERSION}-bin; \
    rm /tmp/apache-log4j-${LOG4J_VERSION}-bin.tar.gz;

ARG SLF4J_VERSION
ENV SLF4J_VERSION=${SLF4J_VERSION:-1.7.32}
ENV SLF4J_JARS="slf4j-api"
ADD https://repo1.maven.org/maven2/org/slf4j/slf4j-api/${SLF4J_VERSION}/slf4j-api-${SLF4J_VERSION}.jar ${LOG_JAR_DIR}/

# Switch tomcat to use log4j2 for its own internal logging.
# See: https://stackoverflow.com/questions/28446085/tomcat-7-internal-logging-with-log4j2-xml/35618384#35618384
#ENV LOGGING_CONFIG_FILE="${CATALINA_HOME}/conf/log4j.xml"
#ENV LOGGING_MANAGER="org.apache.logging.log4j.jul.LogManager"
RUN rm -f ${CATALINA_HOME}/conf/logging.properties; \
    rm -f ${CATALINA_HOME}/lib/log4j.jar

# Set defaults for environment-configurable connector settings.
# Tomcat defaults are listed at https://tomcat.apache.org/tomcat-8.0-doc/config/http.html
ENV CONNECTOR_COMPRESSIBLE_MIME_TYPE "text/html,text/xml,text/plain,text/css,text/javascript,application/javascript,application/json,application/octet-stream,application/xml"
ENV CONNECTOR_COMPRESSION 1000
ENV CONNECTOR_COMPRESSION_MIN_SIZE 2048
ENV CONNECTOR_CONNECTION_TIMEOUT 20000
ENV CONNECTOR_MAX_THREADS 50
ENV CONNECTOR_PROTOCOL "HTTP/1.1"
ENV CONNECTOR_PROXYNAME localhost
ENV CONNECTOR_PROXYPORT 443
ENV CONNECTOR_PROXYSCHEME https
ENV CONNECTOR_PROXYSECURE true
ENV CONNECTOR_SERVER Apache
ENV CONNECTOR_TRUESTED_PROXIES ""

# Set defaults for environment-configurable CORS settings.
ENV CORS_ALLOWED_ORIGINS *
ENV CORS_ALLOWED_METHODS "GET,POST,HEAD,OPTIONS,PUT"
ENV CORS_ALLOWED_HEADERS "Authorization,Origin,Accept,X-Requested-With,Content-Type,Access-Control-Request-Method,Access-Control-Request-Headers"
ENV CORS_EXPOSED_HEADERS ""
ENV CORS_SUPPORT_CREDENTIALS true
ENV CORS_PREFLIGHT_MAXAGE 10

# Ensure the environment-settings are made available to Tomcat at runtime.
COPY ./setenv.sh  ${CATALINA_HOME}/bin/
RUN chmod 755 ${CATALINA_HOME}/bin/setenv.sh

# Deploy customised tomcat configuration files that interpolate our
# custom logging, connector and CORs settings.
COPY ./log4j2.xml ${CATALINA_HOME}/conf/
COPY ./server.xml ${CATALINA_HOME}/conf/
COPY ./web.xml    ${CATALINA_HOME}/conf/


# Start container
ENTRYPOINT ["/entrypoint.sh"]
#CMD ["start-tomcat.sh"]
CMD ["catalina.sh", "run"]

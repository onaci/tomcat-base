# Allow the variant of our base-image to be selected at build time.
ARG BASE_TAG="8.5-jdk11"
ARG BASE_IMAGE="unidata/tomcat-docker:${BASE_TAG}"
FROM ${BASE_IMAGE}

# Record the actual base image used from the FROM command in the build output.
ARG BASE_IMAGE=$BASE_IMAGE
LABEL org.opencontainers.image.base.name=${BASE_IMAGE}

# Run updates for all OS packages in case the base image is old
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install the extension files into the Tomcat configuration directory
ARG LOG4J_VERSION
ENV LOG4J_VERSION=${LOG4J_VERSION:-2.20.0}
COPY ./tomcat/* "${CATALINA_HOME}/conf/"
RUN chmod 0755 "${CATALINA_HOME}/conf/"*.sh \
    && "${CATALINA_HOME}/conf/install_extensions.sh"

# Use the extension entrypoint script and command
ENTRYPOINT ["/entrypoint_wrapper.sh"]
CMD ["catalina.sh", "run"]

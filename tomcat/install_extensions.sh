#!/bin/bash
set -e

THIS_SCRIPT="${BASH_SOURCE[0]}"
THIS_DIR=$( cd "$(dirname "${THIS_SCRIPT}")" && pwd)

# Download and cache an up-to-date version of the Log4j binaries
LOG4J_DIR="/usr/share/java/log4j"
LOG4J_JARS="${LOG4J_JARS:-log4j-core log4j-api log4j-1.2-api log4j-jul log4j-slf4j-impl}"
LOG4J_VERSION="${LOG4J_VERSION:-2.20.0}"
wget -O - "http://archive.apache.org/dist/logging/log4j/${LOG4J_VERSION}/apache-log4j-${LOG4J_VERSION}-bin.tar.gz"  | tar -xz -C /tmp/
mkdir -p "${LOG4J_DIR}"
for LOG4J_JAR in $LOG4J_JARS; do
  cp /tmp/apache-log4j-${LOG4J_VERSION}-bin/${LOG4J_JAR}-${LOG4J_VERSION}.jar ${LOG4J_DIR}/
done
rm -r /tmp/apache-log4j-${LOG4J_VERSION}-bin

# Make sure the log4j binaries will be in the JVM classpath
echo "whoami" >> "${CATALINA_HOME}/bin/setenv.sh"
echo "export CLASSPATH=\"\${CLASSPATH}:${LOG4J_DIR}/*\"" >> "${CATALINA_HOME}/bin/setenv.sh"


# Symiink the entrypoint wrapper script into position
ln -sf "${THIS_DIR}/entrypoint_wrapper.sh" "/entrypoint_wrapper.sh"

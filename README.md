# onaci/tomcat-data-servers

The files in this repository define a set of docker images which are derived from a variety of base images involving
Apache Tomcat, with some common, additional hardening to make the images suitable for use in production.

- [Enhancements](#enhancements)
- [Environment variables](#environment-variables)
- [Docker Images](#docker-images)
  - [tomcat-base](#tomcat-base)
  - [thredds-base](#thredds-base)

&nbsp;

---

## Enhancements

Our additions extend the base image(s) to *also*:

- Use container-level environment variables to configure the Tomcat connector properties, CORs filter properties and Access Logging.
  Use default-connector settings that assume the container is deployed behind a reverse proxy that is handling SSL termination
- Use Log4J for tomcat server logging, so that the tomcat server log configuration *and* tomcat-hosted web application logging can all be controlled by the same configuration file.
- Write all tomcat server and application logs to standard output by default (with no logfiles created inside the container and needing rotation).
- Write all tomcat access log messages to standard output by default
- Optionally suppress access logging completely (for cases where that's handled by an upstream reverse proxy server)

&nbsp;

---

## Environment variables

Images which are built from the dockerfiles in this repository can use the following environment variables to control the tomcat server configuration *in addition* to the ones defined on their base images

| Variable | Purpose | Default Value |
|----------|---------|---------------|
|`ACCESS_LOGGING_ENABLED`| whether this container should log access requests.|`true` to log access requests to stdout. Set this to `false` to suppress access logs by directing them to `/dev/null` (e.g. if that's handled by a reverse proxy webserver).|
|`CONNECTOR_COMPRESSIBLE_MIME_TYPE`| CSV list of MIME types for which HTTP compression may be used|`text/html,text/xml,text/plain,text/css,text/javascript,application/javascript,application/json,application/octet-stream,application/xml`|
|`CONNECTOR_COMPRESSION`|Whether compression of responses is `on` or `off` |`on`|
|`CONNECTOR_COMPRESSION_MIN_SIZE`|The minimum amount of data in a response before that response is compressed |`2048`|
|`CONNECTOR_CONNECTION_TIMEOUT`|The number of milliseconds the tomcat connector will wait after accepting a connection, for the request URI line to be presented|`20000`|
|`CONNECTOR_MAX_THREADS`|The maximum number of request processing threads to be created (simultaneous requests to be handled) by the tomcat connector |`50`|
|`CONNECTOR_PROXY_NAME`|The server name to be returned for calls to `request.getServerName()`|`localhost`|
|`CONNECTOR_PROXY_PORT`|The server port to be returned for calls to `request.getServerPort()`|`443`|
|`CONNECTOR_PROXY_SCHEME`|The name of the protocol that should be returned by calls to `request.getScheme()`|`https`|
|`CONNECTOR_PROXY_SECURE`|Whether the connector is behind a reverse-proxy server that is handling SSL termination|`true`|
|`CONNECTOR_RELAXED_PATH_CHARS`|List of characters that are usually %nnn encoded in URI paths but will also be handled unencoded|(empty string)|
|`CONNECTOR_RELAXED_QUERY_CHARS`|List of characters that are usually %nnn encoded in QueryStrings but will also be handled unencoded|(empty string)|
|`CONNECTOR_SERVER`|Override value for the server header set by a web application (used to obscure that)`|`Apache`|
|`CORS_ALLOWED_ORIGINS`|A list of origins that are allowed to access the hosted web applications|`*` => all origins|
|`CORS_ALLOWED_METHODS`|A CSV list of HTTP methods that are allowed to access the hosted web applications|`GET,POST,HEAD,OPTIONS,PUT`|
|`CORS_ALLOWED_HEADERS`|A CSV list of headers that can be used when making a request and in pre-flight responses|`Authorization,Origin,Accept,X-Requested-With,Content-Type,Access-Control-Request-Method,Access-Control-Request-Headers`|
|`CORS_EXPOSED_HEADERS`|A CSV list of custom headers that browsers are allowed to access in a response|(empty string)|
|`CORS_PREFLIGHT_MAXAGE`|The amount of seconds a browser is allowed to cache the result of a CORS pre-flight request|`10`|
|`CORS_SUPPORT_CREDENTIALS`|Whether user credentials can be included as part of a request. If `true`, `CORS_ALLOWED_ORIGINS`` must NOT be a wildcard|`false`|
|`REMOTE_IP_TRUSTED_PROXIES`|The IP addresses of upstream reverse proxy servers for which the X-FORWARDED-FOR header can be safely interpreted as the IP address of the actual end-user and dereferenced in access logs. |(empty string)|

---

## Docker Images

### tomcat-base

The default [Dockerfile](./Dockerfile) creates a container derived directly from the hardened [unidata/tomcat-docker](https://hub.docker.com/r/unidata/tomcat-docker) base image.

Images built using this dockerfile can be obtained from [onaci/tomcat-base](https://hub.docker.com/r/onaci/tomcat-base) with tags that are a subset of the tags available on the base image.

For containers that use this image, .war files can be mounted below `/usr/local/tomcat/webapps/` at runtime.

&nbsp;

### thredds-base

The  alternate [Dockerfile.thredds-base](./Dockerfile.thredds-base) derives an enhanced THREDDS Data Server image from the  [unidata/thredds-docker](https://hub.docker.com/r/unidata/thredds-docker) base image.

Images built using this dockerfile can be obtained from [onaci/thredds-base](https://hub.docker.com/r/onaci/thredds-base) with tags that are a subset of the tags available on the base image.

For containers that use this image, you should:

- Install your THREDDS configuration files below `/usr/local/tomcat/content/thredds`
- Mount a fast local volume to be used as the THREDDS cache to `/usr/local/tomcat/content/thredds/cache`
- Mount a fast local volume to be used as the JavaUtilPrefs cache at `/usr/local/tomcat/javaUtilPrefs`
- Mount your data storages readonly to whichever absolute path your THREDDS configuration expects to find them at
- Set the `TOMCAT_USER_ID` and `TOMCAT_GROUP_ID` to the UID and GID of a user account with permission to access your data storages
- Set the `THREDDS_XMX_SIZE` and `THREDDS_XMS_SIZE` to appropriate memory limits for your hosting environment
- Remember to cite the [Unidata THREDDS Data Server DOI](https://doi.org/10.5065/D6N014KG)

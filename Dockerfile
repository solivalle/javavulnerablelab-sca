# Stage 1: Build Stage
FROM eclipse-temurin:8-jdk AS build

WORKDIR /app

# Copy the source code into the Docker image
COPY . .

# Install Maven and JDK, then build the project
RUN apt-get update && \
    apt-get install -y maven && \
    mvn clean package && \
    mvn dependency:copy-dependencies -DincludeArtifactIds=mysql-connector-java -DoutputDirectory=/app/shared-libs

# Stage 2: Runtime Stage
FROM tomcat:7.0.82

# Copy the WAR file built in the previous stage
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/

# Copy the JDBC driver into Tomcat's shared lib so the pool DataSource (declared
# in META-INF/context.xml and loaded by the container classloader) can find it.
COPY --from=build /app/shared-libs/*.jar /usr/local/tomcat/lib/

# Copy the pre-prepared tomcat-users.xml to set up user roles
COPY default-tomcat.xml /usr/local/tomcat/conf/tomcat-users.xml

ENV CATALINA_OPTS="-Xms256m -Xmx1024m"

RUN useradd --system --user-group --no-create-home tomcat-runtime && \
    chown -R tomcat-runtime:tomcat-runtime \
        "$CATALINA_HOME/logs" "$CATALINA_HOME/temp" \
        "$CATALINA_HOME/work" "$CATALINA_HOME/webapps"

USER tomcat-runtime

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD bash -ec 'exec 3<>/dev/tcp/127.0.0.1/8080; printf "GET /JavaVulnerableLab/ HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n" >&3; read -r protocol status rest <&3; [[ "$protocol" == HTTP/* && "$status" == [23][0-9][0-9] ]]'

# CMD to start Tomcat
CMD ["catalina.sh", "run"]

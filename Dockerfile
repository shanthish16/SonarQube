# --- STAGE 1: Fetch from Nexus ---
FROM alpine:latest AS fetcher

# These are filled by the --build-arg flags in your Jenkinsfile
ARG NEXUS_USER
ARG NEXUS_PASS
ARG NEXUS_URL

# Path based on your Nexus screenshot
ARG JAR_PATH="com/enterprise/ci/enterprise-ci-java-service/1.0-SNAPSHOT/enterprise-ci-java-service-1.0-SNAPSHOT.jar"

RUN apk add --no-cache curl

# We use the variable ${NEXUS_URL} so it always matches your Jenkinsfile
RUN curl -u ${NEXUS_USER}:${NEXUS_PASS} \
    -L "${NEXUS_URL}/repository/maven-snapshots/${JAR_PATH}" \
    -o /tmp/app.jar

# --- STAGE 2: Lightweight Runtime ---
FROM amazoncorretto:17-alpine
WORKDIR /app
# Only the JAR survives this stage, making the image tiny
COPY --from=fetcher /tmp/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

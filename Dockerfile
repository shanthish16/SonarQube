# --- Stage 1: Fetch the artifact ---
FROM alpine:latest AS fetcher

# Set Nexus variables (these can be passed as --build-arg)
ARG NEXUS_USER
ARG NEXUS_PASS
ARG ARTIFACT_URL="http://13.51.241.14:30081/repository/maven-snapshots/com/enterprise/ci/enterprise-ci-java-service/1.0-SNAPSHOT/enterprise-ci-java-service-1.0-SNAPSHOT.jar"

RUN apk add --no-cache curl

# Download the JAR from Nexus using credentials
RUN curl -u ${NEXUS_USER}:${NEXUS_PASS} -L ${ARTIFACT_URL} -o /tmp/app.jar

# --- Stage 2: Tiny Runtime Image ---
FROM amazoncorretto:17-alpine

WORKDIR /app

# Copy ONLY the jar from the fetcher stage
COPY --from=fetcher /tmp/app.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]

# ---------- STAGE 1: Fetch from Nexus ----------
FROM alpine:latest AS fetcher

ARG NEXUS_USER
ARG NEXUS_PASS
ARG NEXUS_URL

ENV GROUP_PATH=com/enterprise/ci
ENV ARTIFACT=enterprise-ci-java-service
ENV VERSION=1.0-SNAPSHOT

RUN apk add --no-cache curl xmlstarlet

# ----- Fetch latest snapshot -----
RUN METADATA_URL=${NEXUS_URL}/repository/maven-snapshots/${GROUP_PATH}/${ARTIFACT}/${VERSION}/maven-metadata.xml && \
    echo "Downloading metadata..." && \
    curl -u ${NEXUS_USER}:${NEXUS_PASS} -o metadata.xml $METADATA_URL && \
    SNAPSHOT_VERSION=$(xmlstarlet sel -t -v "//snapshotVersion[value[contains(.,'.jar')]]/value" metadata.xml) && \
    echo "Latest snapshot = $SNAPSHOT_VERSION" && \
    curl -u ${NEXUS_USER}:${NEXUS_PASS} \
      -L "${NEXUS_URL}/repository/maven-snapshots/${GROUP_PATH}/${ARTIFACT}/${VERSION}/${ARTIFACT}-${SNAPSHOT_VERSION}.jar" \
      -o /tmp/app.jar


# ---------- STAGE 2: Runtime ----------
FROM amazoncorretto:17-alpine
WORKDIR /app

COPY --from=fetcher /tmp/app.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

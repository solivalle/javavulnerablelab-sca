# checkov:skip=CKV_DOCKER_2:El laboratorio no mantiene una dependencia HTTP; el equipo aprobó omitir HEALTHCHECK. Referencia: AR-2026-001. Vence: 2027-06-30.
FROM eclipse-temurin:17-jre-jammy

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /sbin/nologin lab
WORKDIR /opt/javavulnerablelab

COPY --chown=lab:lab target/*.war /opt/javavulnerablelab/app.war

USER lab
EXPOSE 8080
CMD ["java", "-jar", "/opt/javavulnerablelab/app.war"]


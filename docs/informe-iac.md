# Informe: Analisis de seguridad IaC en el pipeline

## 1. Portada

- Integrantes: completar nombres y matriculas.
- Repositorio: https://github.com/solivalle/javavulnerablelab-sca
- IA utilizada: se utilizo Copilot como apoyo para disenar archivos, comandos y documentacion; las evidencias finales deben validarse en GitHub Actions.

## 2. Linea base local

Comandos utilizados:

```bash
checkov -d infra -d docker --external-checks-dir politicas --compact
```

La tabla final debe completarse con la salida real de la ejecucion local y los cinco hallazgos mas graves.

| Tipo | Fallas finales locales |
|---|---:|
| Terraform | 0 |
| Dockerfile | 0; 1 excepción documentada |
| Docker Compose | 0 |

## 3. Diseno del pipeline

El workflow `.github/workflows/iac-security.yml` se ejecuta en pull requests, push a main y ejecucion manual. El paso SARIF usa `--soft-fail`, publica los hallazgos y no modifica el resultado del trabajo. El gate final ejecuta Checkov sin `--soft-fail` y bloquea el pull request si encuentra una falla.

Versiones fijadas:

- checkov==3.4.5
- ansible-core==2.22.0
- ansible-lint==26.11.0

Las versiones fijadas hacen reproducible el analisis y evitan cambios silenciosos de reglas o comportamiento.

## 4. Evidencia del gate

Abrir un pull request que agrega una regla SSH 0.0.0.0/0 en `infra/main.tf`, esperar el job rojo y adjuntar enlace y capturas. Mantener el PR cerrado sin fusionar.

## 5. Evidencia SARIF

En repositorios publicos, revisar Security -> Code scanning con categoria `iac-checkov`. En repositorio privado sin GitHub Advanced Security, descargar el artefacto `iac-sarif`.

## 6. Remediacion

Completar el antes/despues con resultados reales:

| ID | Recurso | Cambio aplicado | Antes | Despues |
|---|---|---|---|---|
| Base inmovilizada | docker/Dockerfile | Cambia a eclipse-temurin:17-jre-jammy | 3 hallazgos potenciales | Sin fallos |
| Paquetes del sistema | docker/Dockerfile | Actualiza y elimina caches APT | Fallo de imagen | Sin fallo |
| Usuario | docker/Dockerfile | Crea el usuario lab y usa USER | Ejecuta como root | Sin fallo |
| Propiedad de archivos | docker/Dockerfile | Copia archivos con --chown=lab:lab | Archivo propietario de root | Sin fallo |
| Puerto | docker/docker-compose.yml | Publica solo en 127.0.0.1:9080 | Expuesto en todas las interfaces | Sin fallo |
| Sistema de archivos | docker/docker-compose.yml | Habilita read_only: true | Sistema mutable | Sin fallo |
| Privilegios | docker/docker-compose.yml | cap_drop: ALL y no-new-privileges | Capacidades elevadas | Sin fallo |
| Escritorio temporal | docker/docker-compose.yml | Monta /tmp como tmpfs | Escrituras persistentes | Sin fallo |
| CKV_DOCKER_2 | docker/Dockerfile | Excepcion documentada | Sin HEALTHCHECK | Excepcion |

## 7. Excepcion

Existe exactamente una excepcion:

```dockerfile
# checkov:skip=CKV_DOCKER_2:El laboratorio no mantiene una dependencia HTTP; el equipo aprobó omitir HEALTHCHECK. Referencia: AR-2026-001. Vence: 2027-06-30.
```

El riesgo de omitir `HEALTHCHECK` es aceptable temporalmente porque la aplicacion se usa como laboratorio local y no se expone como servicio de produccion. Debe aprobarla el responsable de infraestructura o el lider de seguridad. La revision vence el 2027-06-30.

## 8. Politica propia

`CKV_ORG_1` exige el atributo `tags` en buckets S3 y security groups AWS. La implementacion esta en `politicas/required_tags.yaml` e integrada con `--external-checks-dir politicas`.

- Caso que falla: `politicas/failing-example.tf`
- Caso que pasa: `politicas/passing-example.tf`

## 9. Conclusiones

Checkov detecta reglas conocidas de configuracion, pero no reemplaza revision manual ni prueba runtime. No determina disponibilidad, autentificacion de negocio, secretos almacenados fuera de IaC ni comportamiento explotable. Se cubriria con pruebas DAST, pruebas de infraestructura desplegada en un entorno aislado y revision humana.

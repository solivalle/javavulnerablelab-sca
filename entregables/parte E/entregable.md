# Parte E — Construir el pipeline con Dependency-Check

## Objetivo

Automatizar el análisis de composición de software (SCA) de JavaVulnerableLab mediante OWASP Dependency-Check en GitHub Actions. El pipeline identifica dependencias con vulnerabilidades conocidas, genera reportes HTML, XML y SARIF, publica los hallazgos en Code scanning y conserva los informes como artefactos descargables.

Como paso adicional, un segundo job genera un SBOM CycloneDX en formato JSON y lo conserva como artefacto descargable.

La implementación se encuentra en [sca-dependency-check.yml](../../.github/workflows/sca-dependency-check.yml). Esta entrega documenta su configuración y la ejecución registrada en las capturas adjuntas.

## 1. Activación del workflow y permisos

El workflow se llama `Dependency-Check SCA` y contempla tres formas de ejecución:

- `push` a la rama `main`.
- `pull_request` cuyo destino sea `main`.
- Ejecución manual mediante `workflow_dispatch`, desde la pestaña **Actions**.

Se definen los permisos `contents: read`, para descargar el código, y `security-events: write`, para publicar el reporte SARIF en Code scanning. El trabajo `dependency-check` se ejecuta en una máquina virtual `ubuntu-latest`.

## 2. Uso del secreto NVD_API_KEY

La clave del NVD se administra como secreto de GitHub con el nombre `NVD_API_KEY`, en **Settings → Secrets and variables → Actions**. El YAML únicamente contiene la referencia `${{ secrets.NVD_API_KEY }}`, que se asigna a una variable de entorno del trabajo; el valor de la clave no se escribe en el archivo.

Dependency-Check recibe el nombre de esa variable mediante `-DnvdApiKeyEnvironmentVariable=NVD_API_KEY`. Así se evita incluir la clave directamente en el comando Maven. Las capturas adjuntas no muestran el valor del secreto ni su pantalla de configuración.

## 3. Pasos ejecutados en el pipeline

### 3.1. Descargar el repositorio

El paso **Checkout repository** utiliza `actions/checkout@v4` para descargar el código correspondiente al commit analizado. Esto pone a disposición de Maven el archivo `pom.xml` y los archivos del proyecto.

### 3.2. Preparar Java 17

El paso **Set up Java 17** utiliza `actions/setup-java@v5` para configurar Temurin Java 17. También habilita `cache: maven` para reutilizar los artefactos descargados por Maven.

### 3.3. Recuperar y conservar la base de datos del NVD

El paso **Cache Dependency-Check NVD database** utiliza `actions/cache@v4` con la ruta `~/.dependency-check-data`. El análisis Maven utiliza ese mismo directorio mediante `-DdataDirectory=$HOME/.dependency-check-data`.

La clave de caché incorpora `github.run_id` y `github.run_attempt`, mientras que `restore-keys: dependency-check-ubuntu-v13-` permite buscar una caché previa compatible. Al finalizar correctamente el trabajo, la acción puede guardar la base actualizada con la nueva clave. Esto permite reutilizar los datos entre ejecuciones y actualizar lo necesario, en lugar de comenzar siempre con una base vacía.

La captura general muestra que los pasos de caché y guardado posterior terminaron correctamente. Al no mostrar sus logs desplegados, no permite confirmar un acierto de caché ni medir el ahorro de descarga en esa ejecución.

### 3.4. Ejecutar Dependency-Check y generar reportes

El paso **Run Dependency-Check** ejecuta el plugin Maven de OWASP en su versión `13.0.0`:

```bash
mvn --batch-mode org.owasp:dependency-check-maven:13.0.0:check \
  -Dformats=HTML,XML,SARIF \
  -DdataDirectory=$HOME/.dependency-check-data \
  -DnvdApiKeyEnvironmentVariable=NVD_API_KEY
```

Se utiliza `formats`, en plural, para solicitar los tres formatos. Durante la preparación se corrigió el parámetro inicial `-Dformat=HTML,XML,SARIF`, que provocaba la búsqueda de una plantilla inexistente llamada `HTML,XML,SARIF.vsl`.

Los archivos generados son:

| Archivo | Uso |
|---|---|
| `target/dependency-check-report.html` | Consulta visual del análisis y sus hallazgos. |
| `target/dependency-check-report.xml` | Procesamiento estructurado e importación en herramientas compatibles. |
| `target/dependency-check-report.sarif` | Publicación de resultados en GitHub Code scanning. |

La evidencia del análisis muestra `Analysis Complete`, la escritura de los tres reportes y el resultado **BUILD SUCCESS**. También registra dependencias con vulnerabilidades conocidas, entre ellas Log4j, Commons Collections, Commons FileUpload, Commons IO, dom4j, Hibernate, jQuery y MySQL Connector/J. Una ejecución exitosa indica que el proceso terminó correctamente; los hallazgos siguen requiriendo revisión.

El log muestra además que el analizador Sonatype OSS Index estuvo deshabilitado por falta de credenciales. El análisis continuó y generó los reportes; esa fuente adicional no participó en la ejecución mostrada.

![Evidencia de Dependency-Check: reportes HTML, XML y SARIF generados y BUILD SUCCESS](<./Evidencia Dependency Check.png>)

### 3.5. Publicar el SARIF en Code scanning

El paso **Upload SARIF to GitHub Code Scanning** utiliza `github/codeql-action/upload-sarif@v3`. Selecciona el archivo `target/dependency-check-report.sarif` y establece la categoría `dependencycheck`.

El workflow omite esta publicación cuando el pull request procede de un fork, mediante una condición que comprueba el repositorio de origen. Para las ejecuciones admitidas, los resultados se consultan en **Security → Code scanning**.

La captura de Code scanning muestra **31 alertas abiertas y 0 cerradas**, con el filtro de la rama `main`. Los hallazgos visibles figuran como detectados por `dependency-check` e incluyen alertas críticas en Log4j, dom4j y Commons Collections. La categoría `dependencycheck` está definida en el YAML; no se visualiza en esta captura.

![Hallazgos publicados por Dependency-Check en GitHub Code scanning para main](<./Sarif Code Scanning.png>)

### 3.6. Guardar los informes como artefactos descargables

El paso **Upload HTML and XML reports** utiliza `actions/upload-artifact@v4` y crea el artefacto `dependency-check-reports`. El patrón `target/dependency-check-report.*` incluye los archivos HTML, XML y SARIF.

La condición `if: always()` permite intentar la carga aunque falle un paso anterior. Si no se generaron reportes, `if-no-files-found: warn` emite una advertencia. Para descargarlos, se abre el resumen de la ejecución en **Actions** y se selecciona `dependency-check-reports` en **Artifacts**.

La captura general confirma que el paso de publicación de artefactos terminó correctamente, aunque no muestra el contenido del archivo descargable.

### 3.7. Finalización del trabajo

La captura general registra el trabajo `dependency-check` como exitoso, con una duración total de **1 h 4 min 12 s**. Incluye la descarga del repositorio, Java 17, la caché, el análisis, la publicación SARIF, la carga de reportes y las tareas posteriores de las acciones.

![Pipeline de GitHub Actions con todos sus pasos completados correctamente](<./Gitflow Workflow Pipeline.png>)

## 4. Paso adicional: generar y publicar el SBOM CycloneDX

Se agregó al mismo workflow un segundo job llamado `cyclonedx-sbom`, independiente de `dependency-check`. Ambos comparten los eventos de activación del workflow y pueden ejecutarse en paralelo, ya que no se define una dependencia mediante `needs`.

Este job se ejecuta en `ubuntu-latest` y limita sus permisos a `contents: read`. Descarga el repositorio con `actions/checkout@v4`, prepara Temurin Java 17 con `actions/setup-java@v5` y habilita la caché de Maven. No requiere la clave del NVD para generar el inventario.

### 4.1. Generar el inventario de componentes

El paso **Generate CycloneDX SBOM** utiliza el plugin Maven de CycloneDX en su versión `2.9.3`:

```bash
mvn --batch-mode org.cyclonedx:cyclonedx-maven-plugin:2.9.3:makeAggregateBom \
  -DoutputFormat=json \
  -DoutputName=bom
```

El objetivo `makeAggregateBom` genera el inventario de dependencias directas y transitivas del proyecto. El resultado se escribe en `target/bom.json`. El SBOM describe los componentes del software y complementa los reportes de vulnerabilidades producidos por Dependency-Check.

### 4.2. Guardar el SBOM como artefacto

El paso **Upload CycloneDX SBOM** utiliza `actions/upload-artifact@v4` para publicar `target/bom.json` con el nombre de artefacto `cyclonedx-sbom`. La opción `if-no-files-found: error` hace fallar el paso si el archivo esperado no existe.

Para descargarlo, se abre el resumen de la ejecución en **Actions** y se selecciona **Artifacts → cyclonedx-sbom**.

### 4.3. Evidencia de ejecución

La captura muestra el job `cyclonedx-sbom` completado correctamente en **12 segundos**. En el log se observa la creación de un **BOM CycloneDX versión 1.6 con 18 componentes**, la escritura y validación del archivo JSON en `target/bom.json` y el resultado **BUILD SUCCESS**. El paso **Upload CycloneDX SBOM** también aparece completado correctamente.

Aunque el log contiene advertencias del validador sobre las palabras clave `meta:enum` y `deprecated`, estas no impidieron que el job terminara exitosamente. En el momento de esta captura, el job `dependency-check` todavía estaba en ejecución; la evidencia de su ejecución exitosa se presenta en la sección anterior.

![Generación correcta del SBOM CycloneDX y publicación del artefacto](./SBOM%20CycloneDX.png)

[Ver imagen de evidencia del SBOM CycloneDX](./SBOM%20CycloneDX.png)

## 5. Correspondencia con los requisitos de la Parte E

| N.º | Requisito | Puntos | Implementación y evidencia |
|---|---|---:|---|
| 1 | Ejecutar en push a main, pull_request hacia main y manualmente. | 3 | Eventos `push`, `pull_request` y `workflow_dispatch` definidos en el YAML. Las capturas no acreditan una ejecución independiente de cada evento. |
| 2 | Definir permisos mínimos. | 2 | `contents: read` y `security-events: write`. |
| 3 | Preparar Java 17. | 3 | Temurin Java 17; paso **Set up Java 17** exitoso en la captura general. |
| 4 | Utilizar el secreto NVD_API_KEY sin exponer la clave. | 4 | Referencia al secreto y lectura mediante variable de entorno; no se incluye el valor en el YAML. |
| 5 | Reutilizar la base del NVD con una caché. | 4 | `actions/cache@v4`, directorio compartido con Maven y prefijo de restauración. Pasos de caché exitosos en la captura general. |
| 6 | Generar HTML, XML y SARIF. | 4 | `-Dformats=HTML,XML,SARIF`; el log muestra la escritura de los tres reportes. |
| 7 | Subir SARIF a Code scanning con categoría dependencycheck. | 4 | `upload-sarif@v3` y `category: dependencycheck`; paso exitoso y captura de alertas publicadas. |
| 8 | Conservar HTML y XML como artefactos. | 2 | Artefacto `dependency-check-reports` con el patrón `target/dependency-check-report.*`; paso de carga exitoso. |
| 9 | Explicar cada línea del YAML con un comentario. | 4 | Todas las líneas del workflow incluyen un comentario explicativo. |
| | **Total de la rúbrica** | **30** | |

## 6. Resultado documentado

Las evidencias muestran una ejecución exitosa del pipeline, la generación de HTML, XML y SARIF, la finalización del paso de carga de artefactos y la publicación de hallazgos en Code scanning. El YAML permite comprobar los eventos configurados, los permisos, la referencia al secreto, la estrategia de caché, la categoría SARIF y los comentarios por línea.

La evidencia adicional confirma que el job `cyclonedx-sbom` generó un inventario CycloneDX 1.6 con 18 componentes y completó la carga del artefacto `cyclonedx-sbom`. Este segundo job amplía el workflow sin modificar los 30 puntos de la rúbrica original.

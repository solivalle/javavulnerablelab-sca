# Parte B - Análisis local con OWASP Dependency-Check

## Objetivo

Se ejecutó OWASP Dependency-Check mediante su plugin de Maven para analizar las dependencias de terceros declaradas en el proyecto `JavaVulnerableLab` y contrastarlas con información pública de vulnerabilidades conocidas. El análisis se realizó localmente en macOS desde la raíz del proyecto.

Dependency-Check evalúa las dependencias identificables del proyecto; este resultado no equivale a un análisis completo del código fuente ni a una prueba de penetración.

## Ejecución

Se utilizó el plugin `org.owasp:dependency-check-maven:13.0.0` con la meta `check`. El formato `ALL` solicita todos los formatos de reporte disponibles. Se proporcionó la clave de NVD mediante la propiedad `nvdApiKey` y se deshabilitó el analizador de OSS Index.

La clave API se omitió de este documento. Para mantenerla fuera del historial de comandos, se leyó de forma oculta desde la terminal y se eliminó de la variable de entorno al terminar:

```zsh
read -s "NVD_API_KEY?Pega la clave NVD (no se mostrará): "
export NVD_API_KEY
mvn -B org.owasp:dependency-check-maven:13.0.0:check \
  -Dformat=ALL \
  "-DnvdApiKey=${NVD_API_KEY}" \
  -DossindexAnalyzerEnabled=false
resultado=$?
unset NVD_API_KEY
if (( resultado == 0 )); then
  open target/dependency-check-report.html
fi
```

## Reportes generados

Los informes de la ejecución se encuentran en esta carpeta:

- [Reporte HTML](./dependency-check-report.html): informe navegable para revisión en el navegador.
- [Reporte XML](./dependency-check-report.xml): salida estructurada en XML.
- [Reporte JSON](./dependency-check-report.json): salida estructurada en JSON.
- [Reporte SARIF](./dependency-check-report.sarif): formato interoperable para herramientas de análisis y plataformas de seguridad.
- [Reporte CSV](./dependency-check-report.csv): resultados tabulares para consulta o procesamiento en hojas de cálculo.

Los reportes también se generan en `target/` durante la ejecución de Maven. La carpeta `target/` es un directorio de compilación y está excluida del control de versiones; las copias enlazadas aquí forman parte de la entrega.

## Revisión

Abrir el [reporte HTML](./dependency-check-report.html) para consultar el resumen y el detalle por dependencia. Los reportes XML, JSON, SARIF y CSV permiten reutilizar los resultados en otras herramientas o procesos.
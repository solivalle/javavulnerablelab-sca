# Parte F — Preguntas de análisis

Las respuestas corresponden a las preguntas 19 a 23 de la tarea y se apoyan en los reportes y evidencias conservados en las partes B, C, D y E.

## 19. ¿Qué diferencia hay entre SAST y SCA? ¿Por qué una aplicación necesita ambos?

**SAST** (Static Application Security Testing) analiza estáticamente el código fuente o compilado para identificar posibles defectos de seguridad, por ejemplo una consulta SQL construida con datos de entrada sin tratamiento adecuado. Ayuda a localizar el problema en la implementación de la aplicación. Esta definición corresponde a la descripción de [OWASP sobre análisis estático](https://owasp.org/www-community/Source_Code_Analysis_Tools).

**SCA** (Software Composition Analysis) examina los componentes de terceros que forman parte del software, sus versiones y sus relaciones. Permite identificar dependencias asociadas con vulnerabilidades conocidas y, según la herramienta, revisar también licencias. [Dependency-Check](https://dependency-check.github.io/DependencyCheck/) se utiliza en este laboratorio para detectar componentes con vulnerabilidades conocidas.

La aplicación necesita ambos porque puede contener fallos en su propio código y también incorporar fallos mediante bibliotecas externas. Corregir una consulta insegura no actualiza una biblioteca vulnerable; actualizar una biblioteca tampoco elimina automáticamente una vulnerabilidad en el código de la aplicación.

En este proyecto, el [reporte local](<../parte B/dependency-check-report.json>) identifica `log4j-core:2.12.1` con **CVE-2021-44228**, severidad **CRITICAL** y CVSS 3.1 **10.0**. Este es un resultado de SCA. Un análisis SAST complementario serviría para revisar cómo el código maneja entradas, consultas y operaciones sensibles. Las evidencias entregadas no incluyen una ejecución SAST, por lo que no se atribuyen a esa técnica hallazgos que no fueron comprobados.

## 20. ¿Qué es una dependencia transitiva y por qué es difícil de controlar? Da un ejemplo de este proyecto.

Una dependencia transitiva es una biblioteca que se incorpora porque otra dependencia la necesita, aunque el proyecto no la declare directamente en su `pom.xml`.

Es difícil de controlar porque el desarrollador suele revisar primero las dependencias directas, mientras que las transitivas pueden formar varias capas. Además, al actualizar una dependencia principal pueden cambiar las versiones resueltas de sus componentes internos. Forzar una versión o excluir una biblioteca requiere comprobar compatibilidad para evitar que la aplicación deje de funcionar.

En JavaVulnerableLab se documentó esta relación:

```text
JavaVulnerableLab
└── org.hibernate:hibernate-core:4.0.1.Final
    └── dom4j:dom4j:1.6.1
```

Hibernate está declarado directamente en el [pom.xml](../../pom.xml). `dom4j:1.6.1` llega a través de Hibernate, como muestran las relaciones del [SBOM](<../parte C/bom.json>) y la [captura del Dependency Graph](<../parte C/dependency graph.png>).

El reporte de Dependency-Check asocia esa versión de dom4j con **CVE-2020-10683**, severidad **CRITICAL** y CVSS 3.1 **9.8**, relacionado con el procesamiento de DTD y entidades externas XML. La evidencia del grafo demuestra el origen transitivo; la asociación con el CVE procede del reporte de Dependency-Check, como se explica en la [Parte C](<../parte C/entregable.md>).

## 21. ¿Qué ventaja tiene Dependency-Track, con monitoreo continuo del SBOM, frente a ejecutar Dependency-Check solo en el pipeline?

Dependency-Check en el pipeline proporciona un análisis cuando se ejecuta el workflow. En este repositorio ocurre con un push a `main`, un pull request hacia `main` o una ejecución manual. Si después se publica una vulnerabilidad y no se vuelve a ejecutar el pipeline, los reportes anteriores no se actualizan por sí solos.

La ventaja de [Dependency-Track](https://dependencytrack.org/) es mantener un inventario por proyecto y versión y volver a contrastarlo con información de vulnerabilidades que se actualiza. Así puede detectar un riesgo nuevo en componentes ya inventariados sin necesitar un cambio de código o una compilación nueva. Esto depende de mantener la instancia operativa y sus fuentes de información actualizadas.

En la [Parte C](<../parte C/entregable.md>) se cargó un SBOM con **18 componentes**. Ese inventario permite dar seguimiento a las versiones registradas. Si la composición de la aplicación cambia, es necesario subir un SBOM nuevo para que el seguimiento represente el software realmente utilizado.

El [workflow de la Parte E](../../.github/workflows/sca-dependency-check.yml) también genera `target/bom.json` y lo guarda como artefacto `cyclonedx-sbom`. Actualmente ese job **no lo envía automáticamente a Dependency-Track**; conservar el artefacto no sustituye la carga del SBOM en la plataforma.

## 22. ¿Por qué crees que Dependency-Check y Dependency-Track pueden reportar resultados distintos para el mismo proyecto?

Los resultados pueden variar por los siguientes motivos:

- **Alcance del inventario:** Dependency-Check puede identificar archivos que no están incluidos en un SBOM generado a partir de las dependencias Maven.
- **Fuentes y actualización:** las fuentes activas y la fecha de sincronización de sus datos pueden diferir. En la ejecución local se deshabilitó OSS Index y en el pipeline se observa que no participó por falta de credenciales.
- **Identificación de componentes:** diferencias en las evidencias, nombres, versiones e identificadores pueden producir asociaciones distintas con vulnerabilidades, incluidos falsos positivos o negativos.
- **Configuración y procesamiento:** los analizadores habilitados, las supresiones, el alcance de dependencias y el estado del procesamiento pueden cambiar lo que aparece en los resultados. Un contador en cero requiere revisar el estado de la instancia antes de concluir que no hay vulnerabilidades.

La documentación de [Dependency-Check](https://dependency-check.github.io/DependencyCheck/) reconoce que algunos analizadores pueden producir falsos positivos y negativos. Por su parte, [Dependency-Track](https://dependencytrack.org/) contrasta el inventario con múltiples fuentes de información; utilizar ambas herramientas no garantiza resultados idénticos.

En las evidencias de este proyecto se observan dos diferencias concretas:

1. **jQuery:** Dependency-Check identifica `jquery.min.js` versión `1.6.4`. La importación en DefectDojo contiene **6 hallazgos** relacionados con este componente, pero jQuery no figura entre los 18 componentes del SBOM Maven utilizado en Dependency-Track. La cobertura de entrada ya es diferente.
2. **Componentes frente a hallazgos:** el CSV de DefectDojo contiene **31 hallazgos en 9 componentes**, mientras que el CSV de Dependency-Track lista **18 componentes**. La columna `metrics.vulnerabilities` de este último está vacía y las capturas de la Parte C muestran cero vulnerabilidades. Por ello, esos 18 registros no demuestran que Dependency-Track haya identificado 18 componentes vulnerables.

Ocho de los nueve componentes con hallazgos en DefectDojo también aparecen en el inventario de Dependency-Track. Esto confirma coincidencia de componentes, pero no demuestra coincidencia de CVE o severidades. Para comparar detecciones habría que obtener los hallazgos de ambas herramientas con sus fuentes sincronizadas, identificadores y fechas de análisis.

Evidencias: [reporte JSON de Dependency-Check](<../parte B/dependency-check-report.json>), [CSV de DefectDojo](<../parte D/DefectDojo findings.csv>), [CSV de Dependency-Track](<../parte D/Dependency-Track findings.csv>) y [documentación de la Parte C](<../parte C/entregable.md>).

## 23. Si una librería vulnerable no tiene versión corregida, ¿qué alternativas tienes para gestionar el riesgo?

Primero revisaría si el hallazgo afecta a la versión utilizada y si las funciones o configuraciones vulnerables están presentes en el despliegue. Que una biblioteca aparezca en el inventario no demuestra por sí solo que una vulnerabilidad sea explotable en todos los contextos; esa evaluación debe quedar documentada.

Si el riesgo aplica y no hay una versión corregida, consideraría estas alternativas:

1. **Eliminar la dependencia o la funcionalidad que la requiere**, cuando no sea necesaria. Si es transitiva, revisar si puede excluirse o si puede sustituirse la biblioteca que la incorpora, comprobando compatibilidad.
2. **Migrar a otra biblioteca mantenida** que cubra la misma necesidad. La sustitución requiere adaptar la integración y verificar el comportamiento de la aplicación.
3. **Aplicar un parche o una mitigación del proveedor**, si existe aunque todavía no se haya publicado una versión nueva. Si se mantiene un parche propio, registrar su origen y asumir el mantenimiento necesario.
4. **Reducir la exposición:** deshabilitar la función vulnerable, restringir entradas y acceso, limitar permisos o aislar el servicio. Los controles deben responder al mecanismo del fallo y verificarse; por ejemplo, ante un riesgo de entidades externas XML, evaluar la desactivación de DTD y entidades externas en el parser utilizado.
5. **Posponer o bloquear el despliegue** cuando el impacto y la exposición no puedan reducirse a un nivel aceptable.
6. **Aceptar temporalmente el riesgo**, si corresponde, con un responsable, una justificación, controles compensatorios, una fecha de revisión y seguimiento de futuras correcciones.

En todos los casos mantendría el componente en el SBOM, registraría la decisión en la gestión de hallazgos y repetiría el análisis cuando cambie la biblioteca, su configuración o la información disponible. Suprimir una alerta solo cambia su presentación; no corrige la vulnerabilidad.

En este laboratorio, `dom4j:1.6.1` sirve como ejemplo de una dependencia transitiva cuya remediación debe considerar también Hibernate. Si hipotéticamente no existiera una actualización compatible, evaluaría la migración del componente que la incorpora y controles sobre el procesamiento XML. Esta respuesta plantea alternativas de gestión; no afirma que se hayan aplicado cambios de remediación al proyecto.

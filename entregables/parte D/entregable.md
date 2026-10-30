# Parte D - Importación en DefectDojo y comparación

## Iniciar DefectDojo localmente

El archivo [docker-compose.yml](./docker-compose.yml) incluye el Compose oficial de DefectDojo desde `~/tools/django-DefectDojo/docker-compose.yml`. Docker Compose `include` requiere Compose v2.20 o posterior. La versión disponible al preparar esta entrega era v2.15.1 y rechazó la propiedad `include`; antes de continuar, actualizar Docker Desktop desde Docker Desktop > Check for Updates, instalar la actualización y reiniciar Docker Desktop. Luego comprobar que `docker compose version` muestre v2.20 o posterior.

Con Docker Desktop abierto, descargar una vez el repositorio oficial y arrancar la aplicación desde la raíz de este proyecto:

```zsh
mkdir -p "$HOME/tools"
git clone https://github.com/DefectDojo/django-DefectDojo.git "$HOME/tools/django-DefectDojo"
DD_PORT=8082 docker compose -f 'entregables/parte D/docker-compose.yml' up -d
```

La primera inicialización puede tardar unos minutos. Consultar la contraseña generada para el usuario `admin` con:

```zsh
docker compose -f 'entregables/parte D/docker-compose.yml' logs initializer | grep 'Admin password:'
```

Abrir [http://localhost:8082](http://localhost:8082) e iniciar sesión con `admin` y la contraseña mostrada en esos logs. El Compose oficial usa contenedores separados para la aplicación y sus servicios auxiliares.

Para detener DefectDojo conservando la base de datos y demás datos persistentes:

```zsh
DD_PORT=8082 docker compose -f 'entregables/parte D/docker-compose.yml' down
```

No añadir `--volumes` si se desean conservar los datos.

## Crear el producto e importar el análisis

1. En DefectDojo, crear el producto `JavaVulnerableLab` (seleccionar el tipo de producto disponible para el curso, por ejemplo `Research and Development`).
2. Crear o seleccionar un engagement para ese producto. DefectDojo necesita asociar la importación a un engagement.
3. En el engagement, abrir la función **Import Scan**.
4. Seleccionar el tipo de escaneo **Dependency Check Scan**.
5. Elegir el archivo `target/dependency-check-report.xml` desde la raíz del proyecto y ejecutar la importación. Este XML es el reporte producido por OWASP Dependency-Check.
6. Esperar que termine el procesamiento y revisar los hallazgos del test creado por la importación.

El reporte XML se encuentra localmente en [target/dependency-check-report.xml](../../target/dependency-check-report.xml). La carpeta `target/` está excluida del control de versiones; si se necesita incluir el reporte en la entrega, copiarlo a esta carpeta antes de publicar.

# Comparación de resultados: DefectDojo vs. Dependency-Track

## Archivos utilizados

- `DefectDojo findings.csv`
- `Dependency-Track findings.csv`

## 1. ¿Coinciden las dependencias vulnerables?

**Sí, coinciden parcialmente.** El CSV de Dependency-Track contiene **18 dependencias registradas como vulnerables**. Por su parte, DefectDojo presenta **31 hallazgos de seguridad distribuidos en 9 componentes**.

De los 9 componentes con hallazgos en DefectDojo, **8 también están en el CSV de Dependency-Track**:

- `org.apache.logging.log4j:log4j-core:2.12.1`
- `org.apache.logging.log4j:log4j-api:2.12.1`
- `commons-collections:commons-collections:3.1`
- `commons-fileupload:commons-fileupload:1.3.3`
- `commons-io:commons-io:2.6`
- `dom4j:dom4j:1.6.1`
- `org.hibernate:hibernate-core:4.0.1.Final`
- `mysql:mysql-connector-java:5.1.26`

Por tanto, **existe coincidencia en 8 dependencias vulnerables**, aunque las listas no son idénticas. El CSV de Dependency-Track contiene otras 10 dependencias que no aparecen como componentes con hallazgos en el CSV de DefectDojo.

## 2. ¿Alguna herramienta encontró vulnerabilidades que la otra no?

**Sí, los archivos muestran diferencias en los componentes reportados como vulnerables.** DefectDojo registra **6 hallazgos relacionados con `jquery:1.6.4`**, componente que no aparece en el CSV de Dependency-Track. A su vez, el CSV de Dependency-Track incluye 10 dependencias seleccionadas como vulnerables que no figuran entre los componentes con hallazgos de DefectDojo.

Los **31 hallazgos de DefectDojo** se distribuyen así:

| Severidad | Cantidad |
|---|---:|
| Crítica | 4 |
| Alta | 7 |
| Media | 16 |
| Baja | 4 |
| **Total** | **31** |

Esto permite afirmar que **los conjuntos de componentes vulnerables registrados no coinciden por completo**. 

## 3. ¿Por qué puede ocurrir?

Las diferencias pueden explicarse por los siguientes factores:

1. **Cobertura de componentes diferente:** los archivos no contienen exactamente las mismas dependencias. Por ejemplo, DefectDojo incluye `jquery:1.6.4`, mientras que el CSV de Dependency-Track no lo incluye.
2. **Diferencia en el tipo de información:** DefectDojo presenta hallazgos de seguridad individuales; el CSV de Dependency-Track registra dependencias.
3. **Posibles diferencias en el alcance y las fuentes de análisis:** en general, los resultados pueden variar según los archivos examinados, las fuentes de vulnerabilidades, la configuración y la fecha de actualización. 

## Conclusión

**DefectDojo y Dependency-Track coinciden en 8 componentes vulnerables, pero sus listas no son iguales.** DefectDojo registra 31 hallazgos en 9 componentes, incluido `jquery:1.6.4`, que no aparece en el CSV de Dependency-Track. Este último contiene 18 dependencias registradas como vulnerables, de las cuales 10 no figuran entre los componentes con hallazgos de DefectDojo.

# README: Análisis de la calidad de la vivienda de los hogares con mascotas en el Perú
**Autor:** Eliane Caceres

**Curso:** Taller de Procesamiento de Datos (1SOC03)

**Encuesta:** Encuesta Nacional de Hogares, Instituto Nacional de Estadística e Informática, 2025

**Módulos utilizados:**
- *Módulo 100* – Características de la Vivienda y del Hogar
- *Módulo 118* – Crianza de Mascotas en el Hogar

**Unidad de análisis:** Hogar (hogares que respondieron el módulo 118)

## Descripción del proyecto
Este repositorio incluye el código y el flujo de trabajo completo del proyecto "Análisis de la calidad de la vivienda de los hogares con mascotas en el Perú", elaborado para el curso de Taller de Procesamiento de Datos 2026-1 de la PUCP. Se utilizan datos de la Encuesta Nacional de Hogares (ENAHO) 2025 trabajados íntegramente en R versión 4.4.1. La versión de todas las librerías se controla utilizando renv.

El análisis explora la calidad de la vivienda de los hogares con mascotas en el Perú a partir de tres indicadores de Necesidades Básicas Insatisfechas (NBI), y examina si estas condiciones varían según el tipo de mascota que tienen los hogares y el área geográfica (urbana/rural) en la que residen.

## Estructura del directorio
El directorio se organiza a través de la siguiente estructura de carpetas:
```text
├── datos/                      # No se incluyen los datos en este repositorio debido a su peso
│   ├── crudos/                 # Módulos originales de la ENAHO en formato .csv
│   └── procesados/             # Bases procesadas en formato .parquet
│       ├── enaho_2025_210626.parquet                       # Base consolidada resultado del join entre módulos (script 01)
│       ├── enaho_mascotas_acondicionada_030726.parquet     # Base acondicionada resultado del script 02
│       ├── enaho_mascotas_explorar_030726.parquet          # Base con etiquetas resultado del script 03
│       ├── enaho_mascotas_analitica_030726.parquet         # Base con variables analíticas resultado del script 05
│       └── enaho_mascotas_final_030726.parquet             # Base final con metadatos resultado del script 07
├── scripts/
│   ├── 01_Carga_union_modulos.R       # Carga y cruce (joins) de los módulos 100 y 118
│   ├── 02_Acondicionamiento.R         # Selección, renombrado, diagnóstico y tratamiento de NAs
│   ├── 03_EDA.R                       # EDA univariado y bivariado de variables originales
│   ├── 04_Informe_Exploracion_Inicial.Rmd  # Informe descriptivo en RMarkdown
│   ├── 05_Clasificacion.R             # Creación de variables analíticas
│   ├── 06_EDA_Analitico.R             # EDA de variables analíticas creadas
│   └── 07_Documentacion.R             # Metadatos y generación del codebook final
├── outputs/
│   ├── outputs_exploracion_mascotas/       # Tablas y gráficos del EDA inicial (script 03)
│   ├── outputs_exploracion_analitica/      # Tablas y gráficos del EDA analítico (script 06)
│   ├── Grafico_NAs_Mascotas.png            # Gráfico de diagnóstico de NAs (script 02)
│   ├── Reporte_Datos_Perdidos_Mascotas.csv # Reporte tabular de NAs (script 02)
│   ├── CLASIFICAR_Reporte_VariablesCreadas.html  # Reporte de variables analíticas (script 05)
│   └── CodeBook_codebook.html              # Libro de códigos final generado con el paquete codebook (script 07)
├── docs/                        # Documentos de referencia del proyecto
│   ├── Diccionario_2025.pdf     # Diccionario de datos de la ENAHO 2025
│   └── Ponce_2006_Indice_Calidad_Vivienda.pdf  # Fuente bibliográfica utilizada para la construcción del índice de calidad de vivienda
├── renv/                        # Carpeta aislada del entorno local de paquetes
├── renv.lock                    # Registro exacto de las versiones de las librerías
├── .gitignore                   # Exclusión de datos masivos del repositorio
└── [Nombre_del_Proyecto].Rproj  # Archivo de inicialización del entorno R
```

A continuación, se detalla las principales decisiones y acciones tomadas en cada paso del flujo de trabajo. Si se tienen dudas más específicas, por favor referirse al script correspondiente.

## EXTRAER
Se descargaron los módulos 100 y 118 de la Encuesta Nacional de Hogares 2025. Se guardaron las bases de datos (.csv) en la carpeta de datos crudos, junto con el diccionario de datos de la ENAHO 2025.

## GESTIONAR
Se creó un R.project con el título del trabajo y se realizó la conexión con Git y GitHub desde RStudio. Mediante este proceso, se creó este repositorio de GitHub, el cual es continuamente actualizado a través de commits desde RStudio. En el proyecto, se creó la estructura de carpetas presentada en la sección anterior. Debe tenerse en cuenta que, en este repositorio, las carpetas de "datos" están vacías puesto que se evitó subir las bases de datos para no sobrecargar el repositorio debido a su peso. Esto se realizó especificando en el archivo ".gitignore" que Git ignore los commits asociados a dicha carpeta. No obstante, el presente README especifica los módulos utilizados y cada script permite reproducir y generar las bases de datos procesadas. Finalmente, se utilizó el paquete `renv` para gestionar las versiones de las librerías utilizadas.

## ACONDICIONAR
En el script 01, se realizó la fusión de los módulos 100 y 118 mediante un left_join por las llaves conglome, vivienda y hogar. El módulo 118 fue resumido a una fila por hogar antes del join, dado que originalmente contiene hasta tres filas por hogar (una por cada tipo de mascota). Adicionalmente, el módulo 100 fue filtrado al periodo julio-diciembre 2025 para que coincida con la cobertura temporal del módulo 118, que fue aplicado como sub-muestra únicamente en ese periodo. Como resultado, se exportó la primera base de datos procesada.

En el script 02, se seleccionaron y renombraron las variables de interés, se realizó una revisión rápida de la estructura de los datos y se realizó un diagnóstico de valores perdidos, el cual dio como resultado dos reportes (uno gráfico y otro tabular) que pueden encontrarse en la carpeta "outputs". En cuanto al tratamiento de NAs en las variables NBI (nbi1, nbi2, nbi3), se determinó que los NAs no representaban datos perdidos sino hogares no elegibles para la sub-muestra del módulo 118. Por tanto, se aplicó un filtro estructural (filter(!is.na(tiene_mascota))) que elimina estos casos, quedándonos estrictamente con el universo válido de análisis. Tras este filtro, las tres variables NBI presentaron únicamente valores 0 y 1, sin ningún NA residual, lo que confirmó la decisión tomada. Como resultado, se exportó la segunda base de datos procesada.

**Nota metodológica:** La sub-muestra del módulo 118 presenta una distribución geográfica desbalanceada (71.9% urbano vs 28.1% rural), lo que puede subestimar los niveles de NBI insatisfecha a nivel nacional. Si bien el factor de expansión `factor_s` corrige parcialmente este desbalance, los resultados deben interpretarse con cautela, especialmente en el análisis por área geográfica.

## EXPLORAR
En el script 03, se cargó la base procesada más reciente y, de manera previa a la creación de gráficos y tablas, se crearon etiquetas para las variables de interés guiándose del diccionario de datos de la ENAHO 2025. Posteriormente, se realizó un análisis exploratorio de datos (EDA) univariado y bivariado organizado en cinco secciones: (1) cuántos hogares tienen mascotas, (2) qué tipo de mascotas tienen, (3) cómo son las condiciones de vivienda de los hogares con mascotas, (4) si las condiciones varían según tipo de mascota, y (5) si hay diferencias entre área urbana y rural. En todo el EDA se utilizó el factor de expansión `factor_s`. Los gráficos y tablas resultantes fueron exportados a la subcarpeta "outputs_exploracion_mascotas" y utilizados en el informe descriptivo del script 04_Infrome_Exploración_Inicial.Rmd. Cada tabla y gráfico tiene un propósito narrativo explícito que sirve como evidencia para justificar las decisiones tomadas en el script de clasificación. Como resultado, se exportó la tercera base de datos procesada, que incluye las etiquetas de las variables.

## CLASIFICAR
En el script 05, se crean las siguientes variables analíticas:

- **indice_cv:** Índice de Calidad de Vivienda construido mediante la suma simple de nbi1 + nbi2 + nbi3. Rango: 0 (ninguna NBI) a 3 (las tres NBI). Metodología: INEI.
- **categoria_cv:** Categorización ordinal del índice. Combina la metodología del INEI (pobre por NBI = al menos una necesidad insatisfecha) con la lógica de clasificación propuesta por Ponce (2006): buena calidad (0 NBI), mala calidad (1 NBI) y muy mala calidad (2 o más NBI).
- **tipologia_mascota:** Clasificación MECE (Mutuamente Excluyente, Colectivamente Exhaustiva) de los hogares según el tipo de mascota que tienen: solo perro, solo gato, solo otra mascota, perro y gato, perro y otra mascota, gato y otra mascota, y perro gato y otra mascota.

Como resultado del script 05, se exportó en HTML un reporte de las variables creadas (gtsummary), así como la cuarta base de datos procesada. De manera adicional, en el script 06 se utilizaron las variables analíticas creadas para hacer un nuevo EDA, con tablas y gráficos exportados a la carpeta "outputs_exploracion_analitica".

## DOCUMENTAR
En el script 07, se realizó la depuración final de la base de datos, quedándonos con las variables utilizadas en el EDA de variables analíticas. Asimismo, se incluye etiquetas descriptivas y la fuente original de cada variable (su nombre en la ENAHO), así como metadatos con información sobre las decisiones metodológicas tomadas y la descripción de la creación de las variables analíticas. Con esta información, se generó el libro de códigos final utilizando el paquete `codebook`, exportado en formato HTML a la carpeta "outputs" (CodeBook_codebook.html). En este archivo se describe detalladamente el significado de las variables, las opciones de respuesta, su distribución y las decisiones metodológicas tomadas en cada etapa. Como parte de la documentación, en la carpeta "docs" se puede encontrar el diccionario de datos de la ENAHO 2025, así como la fuente bibliográfica utilizada para la construcción del índice de calidad de vivienda (Ponce Sernicharo, 2006).

## BIBLIOGRAFÍA
- Ponce, G. (2006). Construcción de un Índice de Calidad de la Vivienda. *La vivienda en México: Escribiendo el futuro,* pp. 169-186. https://infonavit.smart-ed.mx/cgi-bin/koha/opac-retrieve-file.pl?id=27756b6382f90cbf5d68d36d81f4ecbf 

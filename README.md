# Análisis de la calidad de la vivienda de los hogares con mascotas en el Perú

## Descripción del proyecto

Este repositorio contiene el código y el flujo de trabajo del informe sobre la **tenencia de mascotas en los hogares peruanos**, elaborado para el curso de *Taller de Procesamiento de Datos* de la PUCP.

Se utilizan datos de la **Encuesta Nacional de Hogares (ENAHO) 2025**, específicamente:

- **Módulo 100** – Características de la Vivienda y del Hogar
- **Módulo 118** – Crianza de Mascotas en el Hogar

El análisis explora la relación entre la tenencia de mascotas y las siguientes dimensiones:

**Geográficas**: zona urbana o rural del hogar (estrato geográfico)

**Socioeconómicas**: material predominante de la vivienda y acceso a servicios básicos (agua, electricidad, internet), como proxy del nivel socioeconómico del hogar

## Programas y librerías utilizadas
El proyecto está desarrollado utilizando la versión 4.4.1 de **R**, con las siguientes librerías:

* `rio`: importación de los módulos de la ENAHO
* `tidyverse`: procesamiento de datos (`dplyr`) y eventuales gráficos (`ggplot2`)
* `janitor`: limpieza y estandarización de los nombres de columnas
* `arrow`: exportación e importación de base de datos en formato parquet

La versión de todas las librerías se controla utilizando `renv`.

## Estructura del directorio
El directorio se organiza a través de la siguiente estructura de carpetas:
```text
├── Creacion_R_Project.R             # Script principal: Configuración del entorno, creación de carpetas y enlace a GitHub
├── datos/
│   ├── crudos/                      # Módulos originales de la ENAHO en formato .csv (módulo 100 y 118)
│   └── procesados/                  # Bases procesadas en formato .parquet (Output de scripts 01)
├── scripts/
│   ├── 01_cargar_datos.R            # Carga masiva y cruce (merge) de los módulos 100 y 118 
├── resultados/                      # Outputs finales: tablas, gráficos descriptivos y el informe en .pdf
├── renv/                            # Carpeta aislada del entorno local de paquetes
├── renv.lock                        # "Cápsula del tiempo": Registro exacto de las versiones de las librerías
├── .gitignore                       # Configuración de exclusión para evitar la subida de datos masivos al repositorio
└── [Mascotas-ENAHO-2025].Rproj      # Archivo de inicialización del entorno R
```

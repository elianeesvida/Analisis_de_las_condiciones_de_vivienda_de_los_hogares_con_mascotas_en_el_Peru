# ==============================================================================
# Proyecto: Análisis de la calidad de la vivienda de los hogares con
#           mascotas en el Perú, 2025
# Script: Documentación
# Autor: Eliane Caceres
# Fecha: 03-07-2026
# Objetivo: Añadir metadatos a la base analítica y generar el codebook final.
# ==============================================================================

rm(list = ls())

# ------------------------------------------------------------------------------
# 0. CONFIGURACIÓN Y PAQUETES--------------------------------------------------
# ------------------------------------------------------------------------------
install.packages(c("labelled", "codebook", "dataMaid"))

library(tidyverse)
library(arrow)
library(here)
library(labelled)
library(codebook)
library(dataMaid)
renv::snapshot()

# Cargamos la base analítica final
enaho_final <- read_parquet(here("datos", "procesados", "enaho_mascotas_analitica_030726.parquet"))

# ==============================================================================
# 1. SELECCIÓN DE VARIABLES PARA EL CODEBOOK-----------------------------------
# ==============================================================================
# Nos quedamos solo con las variables que usamos en el análisis
enaho_codebook <- enaho_final %>%
  filter(tiene_mascota == TRUE) %>%
  select(
    # Variables originales
    nbi1, nbi2, nbi3,
    tiene_mascota, tiene_perro, tiene_gato, tiene_otra_mascota,
    area,
    factor_s,
    # Variables analíticas creadas
    indice_cv,
    categoria_cv,
    tipologia_mascota
  ) %>%
  mutate(across(where(is.character), as.factor))

# Exportamos como base final del proyecto
write_parquet(enaho_codebook,
              here("datos", "procesados", "enaho_mascotas_final_030726.parquet"))

# ==============================================================================
# 2. INYECCIÓN DE METADATOS----------------------------------------------------
# ==============================================================================

# A. Variables originales
var_label(enaho_codebook$nbi1) <- "Vivienda con características físicas inadecuadas (Fuente: Módulo 100 - ENAHO 2025)"
var_label(enaho_codebook$nbi2) <- "Vivienda con hacinamiento (Fuente: Módulo 100 - ENAHO 2025)"
var_label(enaho_codebook$nbi3) <- "Vivienda sin desagüe de ningún tipo (Fuente: Módulo 100 - ENAHO 2025)"
var_label(enaho_codebook$tiene_mascota) <- "Hogar con al menos una mascota (Fuente: P118B - Módulo 118 - ENAHO 2025)"
var_label(enaho_codebook$tiene_perro) <- "Hogar con perro (Fuente: P118A1=1, P118B=1 - Módulo 118 - ENAHO 2025)"
var_label(enaho_codebook$tiene_gato) <- "Hogar con gato (Fuente: P118A1=2, P118B=1 - Módulo 118 - ENAHO 2025)"
var_label(enaho_codebook$tiene_otra_mascota) <- "Hogar con otra mascota (Fuente: P118A1=3, P118B=1 - Módulo 118 - ENAHO 2025)"
var_label(enaho_codebook$area) <- "Área geográfica del hogar (Urbano/Rural)"
var_label(enaho_codebook$factor_s) <- "Factor de expansión de la sub-muestra de mascotas (Fuente: FACTOR_S - Módulo 118 - ENAHO 2025)"

# B. Variables analíticas creadas
var_label(enaho_codebook$indice_cv) <- "Índice de Calidad de Vivienda (suma de NBI insatisfechas)"
var_label(enaho_codebook$categoria_cv) <- "Categoría de Calidad de Vivienda (Buena, Mala, Muy mala)"
var_label(enaho_codebook$tipologia_mascota) <- "Tipología MECE de Tenencia de Mascotas"



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



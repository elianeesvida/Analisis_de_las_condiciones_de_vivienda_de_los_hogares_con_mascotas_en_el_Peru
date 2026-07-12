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

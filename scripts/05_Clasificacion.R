# ==============================================================================
# Proyecto: Análisis de la calidad de la vivienda de los hogares con
#           mascotas en el Perú
# Script: Clasificación
# Autor: Eliane Caceres
# Fecha: 03-07-2026
# Objetivo: Crear variables analíticas para el análisis de la calidad de
#           la vivienda de los hogares con mascotas en el Perú
# ==============================================================================

rm(list = ls())

# ------------------------------------------------------------------------------
# 0. CONFIGURACIÓN Y CARGA DE DATOS--------------------------------------------
# ------------------------------------------------------------------------------
library(tidyverse)
library(arrow)
library(survey)
library(srvyr)
library(here)
library(gtsummary)
library(flextable)
renv::snapshot()

# Cargamos la base explorada
enaho_explorar <- read_parquet(here("datos", "procesados", "enaho_mascotas_explorar_030726.parquet"))


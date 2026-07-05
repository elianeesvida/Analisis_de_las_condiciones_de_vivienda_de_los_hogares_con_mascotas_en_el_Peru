# ==============================================================================
# Proyecto: Análisis de las condiciones de vivienda de los hogares con mascotas en el Perú
# Script: Exploración (EDA)
# Autor: Eliane Caceres
# Fecha: 04-07-2026
# Objetivo: Describir la distribución de la tenencia de mascotas y las
#           condiciones de vivienda (NBI) a nivel nacional y por área
# ==============================================================================

rm(list = ls())

# ------------------------------------------------------------------------------
# 0. CONFIGURACIÓN Y CARGA DE DATOS--------------------------------------------
# ------------------------------------------------------------------------------
library(tidyverse)
library(arrow)
library(survey)
library(srvyr)
library(flextable)
library(scales)
library(officer)
library(here)
renv::snapshot()

enaho_mascotas <- read_parquet(here("datos", "procesados", "enaho_mascotas_acondicionada_030726.parquet"))


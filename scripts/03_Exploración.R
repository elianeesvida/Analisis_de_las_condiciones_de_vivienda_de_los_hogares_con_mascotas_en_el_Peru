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

# ------------------------------------------------------------------------------
# 0.1 NOTA METODOLÓGICA: Distribución de la sub-muestra por área--------------------------------------------
# ------------------------------------------------------------------------------

tabla_cobertura <- enaho_explorar %>%
  filter(!is.na(area)) %>%
  count(area) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  rename(`Área` = area, `Hogares en muestra` = n, `%` = pct)

print(tabla_cobertura)

# NOTA METODOLÓGICA: Distribución de la sub-muestra por área
# La sub-muestra del módulo 118 presenta una distribución geográfica
# desbalanceada: 71.9% de hogares en áreas urbanas vs 28.1% en rurales.
# Esto puede subestimar los niveles de NBI insatisfecha a nivel nacional,
# dado que las zonas rurales concentran peores condiciones de vivienda.
# Si bien el factor de expansión (factor_s) corrige parcialmente este
# desbalance, los resultados deben interpretarse con cautela,
# especialmente en el análisis por área geográfica.














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
# 1. PREPARACIÓN DE ETIQUETAS--------------------------------------------------
# ------------------------------------------------------------------------------
enaho_explorar <- enaho_mascotas %>%
  mutate(
    # A. Tenencia de mascotas
    tiene_mascota_etiqueta = factor(tiene_mascota,
                                    levels = c(FALSE, TRUE),
                                    labels = c("Sin mascota", "Con mascota")),
    tiene_perro_etiqueta = factor(tiene_perro,
                                  levels = c(FALSE, TRUE),
                                  labels = c("Sin perro", "Con perro")),
    tiene_gato_etiqueta = factor(tiene_gato,
                                 levels = c(FALSE, TRUE),
                                 labels = c("Sin gato", "Con gato")),
    tiene_otra_mascota_etiqueta = factor(tiene_otra_mascota,
                                         levels = c(FALSE, TRUE),
                                         labels = c("Sin otra mascota", "Con otra mascota")),
    
    # B. Condiciones de vivienda - NBI
    nbi1_etiqueta = factor(nbi1, levels = c(0, 1),
                           labels = c("Vivienda adecuada", "Vivienda inadecuada")),
    nbi2_etiqueta = factor(nbi2, levels = c(0, 1),
                           labels = c("Sin hacinamiento", "Con hacinamiento")),
    nbi3_etiqueta = factor(nbi3, levels = c(0, 1),
                           labels = c("Con servicios higiénicos", "Sin servicios higiénicos")),
    
    # C. Área geográfica
    # Estratos 1-4: Lima Metropolitana, Costa urbana, Sierra urbana, Selva urbana
    # Estratos 5-8: Costa rural, Sierra rural, Selva rural, Lima rural
    area = case_when(
      estrato %in% c(1, 2, 3, 4, 5,6) ~ "Urbano",
      estrato %in% c(7, 8) ~ "Rural",
      TRUE                        ~ NA_character_
    ),
    area = factor(area, levels = c("Urbano", "Rural")),
    
    # D. Limpieza numérica
    estrato  = as.numeric(estrato),
    conglome = as.numeric(conglome),
    factor_s = as.numeric(factor_s)
  )

write_parquet(enaho_explorar, "datos/procesados/enaho_mascotas_explorar_030726.parquet")

# ------------------------------------------------------------------------------
# NOTA METODOLÓGICA: Distribución de la sub-muestra por área--------------------------------------------
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


# ------------------------------------------------------------------------------
# 2. DISEÑO MUESTRAL-----------------------------------------------------------
# ------------------------------------------------------------------------------
# Diseño completo (todas las observaciones)
enaho_diseno <- enaho_explorar %>%
  filter(!is.na(factor_s)) %>%
  as_survey_design(ids = conglome, strata = estrato,
                   weights = factor_s, nest = TRUE)

# Diseño restringido a hogares CON mascota (secciones 3, 4 y 5)
enaho_diseno_mascotas <- enaho_explorar %>%
  filter(!is.na(factor_s) & tiene_mascota == TRUE) %>%
  as_survey_design(ids = conglome, strata = estrato,
                   weights = factor_s, nest = TRUE)



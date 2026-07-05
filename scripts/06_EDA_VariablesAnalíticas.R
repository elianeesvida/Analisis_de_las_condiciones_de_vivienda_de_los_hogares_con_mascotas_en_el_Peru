# ==============================================================================
# Proyecto: Análisis de la calidad de la vivienda de los hogares con
#           mascotas en el Perú
# Script: EDA con variables analíticas
# Autor: Eliane Caceres
# Fecha: 03-07-2026
# Objetivo: Explorar las variables analíticas creadas en el script de
#           clasificación
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
library(flextable)
library(officer)
renv::snapshot()

# Cargamos la base analítica
enaho_analitica <- read_parquet(here("datos", "procesados", "enaho_mascotas_analitica_030726.parquet"))

# ------------------------------------------------------------------------------
# 1. DISEÑO MUESTRAL-----------------------------------------------------------
# ------------------------------------------------------------------------------
enaho_diseno <- enaho_analitica %>%
  filter(!is.na(factor_s) & tiene_mascota == TRUE) %>%
  as_survey_design(
    ids     = conglome,
    strata  = estrato,
    weights = factor_s,
    nest    = TRUE
  )

# ==============================================================================
# 2. FUNCIÓN DE ESTILO PARA TABLAS---------------------------------------------
# ==============================================================================
estilo_reporte <- function(ft, titulo, fuente) {
  ft %>%
    add_header_lines(values = titulo) %>%
    add_footer_lines(values = fuente) %>%
    autofit() %>%
    border_remove() %>%
    hline_top(border = fp_border(width = 1.5), part = "header") %>%
    hline_bottom(border = fp_border(width = 1.5), part = "header") %>%
    hline_bottom(border = fp_border(width = 1.5), part = "body") %>%
    align(align = "center", part = "all") %>%
    align(j = 1, align = "left", part = "body") %>%
    bold(part = "header") %>%
    align(align = "left", part = "footer") %>%
    fontsize(size = 9, part = "footer")
}

# ==============================================================================
# 3. EXPLORACIÓN UNIVARIADA----------------------------------------------------
# ==============================================================================

# ------------------------------------------------------------------------------
# 3.1 Tabla: Distribución de la calidad de vivienda----------------------------
# ------------------------------------------------------------------------------
tabla_categoria_cv_datos <- enaho_diseno %>%
  filter(!is.na(categoria_cv)) %>%
  group_by(categoria_cv) %>%
  summarise(
    Hogares    = survey_total(vartype = NULL),
    Porcentaje = survey_mean(vartype = NULL) * 100
  ) %>%
  mutate(
    Hogares    = scales::comma(round(Hogares, 0)),
    Porcentaje = paste0(round(Porcentaje, 1), "%")
  ) %>%
  rename(
    `Calidad de vivienda` = categoria_cv,
    `Total (N)`           = Hogares,
    `%`                   = Porcentaje
  )

tabla_categoria_cv <- flextable(tabla_categoria_cv_datos) %>%
  estilo_reporte(
    titulo = "Tabla 1. Perú: Hogares con mascotas según calidad de vivienda, 2025",
    fuente = "Fuente: ENAHO 2025. Cálculos expandidos a nivel poblacional."
  )
tabla_categoria_cv

# Gráfico 1: Distribución de calidad de vivienda
plot_categoria_cv <- ggplot(
  enaho_analitica %>% filter(tiene_mascota == TRUE & !is.na(categoria_cv)),
  aes(x = categoria_cv, weight = factor_s, fill = categoria_cv)) +
  geom_bar(alpha = 0.85) +
  scale_y_continuous(labels = scales::comma) +
  scale_fill_manual(values = c(
    "Buena calidad"    = "#4575B4",
    "Mala calidad"     = "#FDB863",
    "Muy mala calidad" = "#D73027"
  )) +
  labs(
    title   = "Gráfico 1. Perú: Hogares con mascotas según calidad de vivienda, 2025",
    x       = "Calidad de vivienda",
    y       = "Hogares (frecuencia poblacional)",
    caption = "Fuente: ENAHO 2025"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
print(plot_categoria_cv)

# ------------------------------------------------------------------------------
# 3.2 Tabla: Distribución de la tipología de mascotas--------------------------
# ------------------------------------------------------------------------------
tabla_tipologia_datos <- enaho_diseno %>%
  filter(!is.na(tipologia_mascota)) %>%
  group_by(tipologia_mascota) %>%
  summarise(
    Hogares    = survey_total(vartype = NULL),
    Porcentaje = survey_mean(vartype = NULL) * 100
  ) %>%
  mutate(
    Hogares    = scales::comma(round(Hogares, 0)),
    Porcentaje = paste0(round(Porcentaje, 1), "%")
  ) %>%
  arrange(desc(parse_number(str_remove(Hogares, ",")))) %>%
  rename(
    `Tipo de mascota` = tipologia_mascota,
    `Total (N)`       = Hogares,
    `%`               = Porcentaje
  )

tabla_tipologia <- flextable(tabla_tipologia_datos) %>%
  estilo_reporte(
    titulo = "Tabla 2. Perú: Hogares con mascotas según tipología de tenencia, 2025",
    fuente = "Fuente: ENAHO 2025. Cálculos expandidos a nivel poblacional."
  )
tabla_tipologia

# Gráfico 2: Distribución de tipología de mascotas
plot_tipologia <- ggplot(
  enaho_analitica %>% filter(tiene_mascota == TRUE & !is.na(tipologia_mascota)),
  aes(x = reorder(tipologia_mascota, factor_s), weight = factor_s)) +
  geom_bar(fill = "#2E5B88", alpha = 0.85) +
  scale_y_continuous(labels = scales::comma) +
  coord_flip() +
  labs(
    title   = "Gráfico 2. Perú: Hogares con mascotas según tipología de tenencia, 2025",
    x       = "Tipología de mascota",
    y       = "Hogares (frecuencia poblacional)",
    caption = "Fuente: ENAHO 2025"
  ) +
  theme_minimal()
print(plot_tipologia)

# ==============================================================================
# 4. EXPLORACIÓN BIVARIADA-----------------------------------------------------
# ==============================================================================

# ------------------------------------------------------------------------------
# 4.1 Calidad de vivienda según tipología de mascota---------------------------
# ------------------------------------------------------------------------------
tabla_cv_tipologia_datos <- enaho_diseno %>%
  filter(!is.na(categoria_cv) & !is.na(tipologia_mascota)) %>%
  group_by(tipologia_mascota, categoria_cv) %>%
  summarise(Hogares = survey_total(vartype = NULL)) %>%
  group_by(tipologia_mascota) %>%
  mutate(
    Porcentaje = (Hogares / sum(Hogares)) * 100,
    Celda = paste0(scales::comma(round(Hogares, 0)),
                   " (", round(Porcentaje, 1), "%)")
  ) %>%
  select(tipologia_mascota, categoria_cv, Celda) %>%
  pivot_wider(names_from = categoria_cv, values_from = Celda) %>%
  rename(`Tipo de mascota` = tipologia_mascota)

tabla_cv_tipologia <- flextable(tabla_cv_tipologia_datos) %>%
  estilo_reporte(
    titulo = "Tabla 3. Perú: Calidad de vivienda según tipología de tenencia de mascotas, 2025",
    fuente = "Fuente: ENAHO 2025 - Módulo 118. Cálculos expandidos a nivel poblacional."
  )
tabla_cv_tipologia

# Gráfico 3: Calidad de vivienda por tipología de mascota
plot_cv_tipologia <- ggplot(
  enaho_analitica %>% filter(tiene_mascota == TRUE &
                               !is.na(categoria_cv) &
                               !is.na(tipologia_mascota)),
  aes(x = tipologia_mascota, fill = categoria_cv, weight = factor_s)) +
  geom_bar(position = "fill", alpha = 0.85) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c(
    "Buena calidad"    = "#4575B4",
    "Mala calidad"     = "#FDB863",
    "Muy mala calidad" = "#D73027"
  )) +
  coord_flip() +
  labs(
    title   = "Gráfico 3. Perú: Calidad de vivienda según tipología de tenencia de mascotas, 2025",
    x       = "Tipología de mascota",
    y       = "Proporción de hogares",
    fill    = "Calidad de vivienda:",
    caption = "Fuente: ENAHO 2025"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")
print(plot_cv_tipologia)

# ------------------------------------------------------------------------------
# 4.2 Calidad de vivienda según área geográfica--------------------------------
# ------------------------------------------------------------------------------
tabla_cv_area_datos <- enaho_diseno %>%
  filter(!is.na(categoria_cv) & !is.na(area)) %>%
  group_by(area, categoria_cv) %>%
  summarise(Hogares = survey_total(vartype = NULL)) %>%
  group_by(area) %>%
  mutate(
    Porcentaje = (Hogares / sum(Hogares)) * 100,
    Celda = paste0(scales::comma(round(Hogares, 0)),
                   " (", round(Porcentaje, 1), "%)")
  ) %>%
  select(area, categoria_cv, Celda) %>%
  pivot_wider(names_from = categoria_cv, values_from = Celda) %>%
  rename(`Área geográfica` = area)

tabla_cv_area <- flextable(tabla_cv_area_datos) %>%
  estilo_reporte(
    titulo = "Tabla 4. Perú: Calidad de vivienda en hogares con mascotas según área geográfica, 2025",
    fuente = "Fuente: ENAHO 2025. Cálculos expandidos a nivel poblacional."
  )
tabla_cv_area

# Gráfico 4: Calidad de vivienda por área
plot_cv_area <- ggplot(
  enaho_analitica %>% filter(tiene_mascota == TRUE &
                               !is.na(categoria_cv) &
                               !is.na(area)),
  aes(x = area, fill = categoria_cv, weight = factor_s)) +
  geom_bar(position = "fill", alpha = 0.85) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c(
    "Buena calidad"    = "#4575B4",
    "Mala calidad"     = "#FDB863",
    "Muy mala calidad" = "#D73027"
  )) +
  labs(
    title   = "Gráfico 4. Perú: Calidad de vivienda en hogares con mascotas según área geográfica, 2025",
    x       = "Área geográfica",
    y       = "Proporción de hogares",
    fill    = "Calidad de vivienda:",
    caption = "Fuente: ENAHO 2025"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")
print(plot_cv_area)

# ------------------------------------------------------------------------------
# 4.3 Calidad de vivienda según tipología de mascota y área (triple cruce)-----
# ------------------------------------------------------------------------------
tabla_cv_tipo_area_datos <- enaho_diseno %>%
  filter(!is.na(categoria_cv) & !is.na(tipologia_mascota) & !is.na(area)) %>%
  group_by(area, tipologia_mascota, categoria_cv) %>%
  summarise(Hogares = survey_total(vartype = NULL)) %>%
  group_by(area, tipologia_mascota) %>%
  mutate(
    Porcentaje = (Hogares / sum(Hogares)) * 100,
    Celda = paste0(scales::comma(round(Hogares, 0)),
                   " (", round(Porcentaje, 1), "%)")
  ) %>%
  select(area, tipologia_mascota, categoria_cv, Celda) %>%
  pivot_wider(names_from = categoria_cv, values_from = Celda) %>%
  rename(`Área` = area, `Tipo de mascota` = tipologia_mascota)

tabla_cv_tipo_area <- flextable(tabla_cv_tipo_area_datos) %>%
  estilo_reporte(
    titulo = "Tabla 5. Perú: Calidad de vivienda según tipología de mascota y área geográfica, 2025",
    fuente = "Fuente: ENAHO 2025. Cálculos expandidos a nivel poblacional."
  ) %>%
  merge_v(j = "Área")
tabla_cv_tipo_area

# Gráfico 5: Triple cruce facetado por área
plot_cv_tipo_area <- ggplot(
  enaho_analitica %>% filter(tiene_mascota == TRUE &
                               !is.na(categoria_cv) &
                               !is.na(tipologia_mascota) &
                               !is.na(area)),
  aes(x = tipologia_mascota, fill = categoria_cv, weight = factor_s)) +
  geom_bar(position = "fill", alpha = 0.85) +
  facet_wrap(~area) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c(
    "Buena calidad"    = "#4575B4",
    "Mala calidad"     = "#FDB863",
    "Muy mala calidad" = "#D73027"
  )) +
  coord_flip() +
  labs(
    title   = "Gráfico 5. Perú: Calidad de vivienda según tipología de mascota y área geográfica, 2025",
    x       = "Tipología de mascota",
    y       = "Proporción de hogares",
    fill    = "Calidad de vivienda:",
    caption = "Fuente: ENAHO 2025"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")
print(plot_cv_tipo_area)


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

# ------------------------------------------------------------------------------
# 3. FUNCIÓN DE FORMATO FLEXTABLE----------------------------------------------
# ------------------------------------------------------------------------------
formato_flextable <- function(tabla, titulo) {
  flextable(tabla) %>%
    add_header_lines(values = titulo) %>%
    add_footer_lines(values = "Fuente: ENAHO 2025. Cálculos expandidos a nivel poblacional.") %>%
    autofit() %>%
    theme_vanilla() %>%
    border_inner_h(part = "body", border = officer::fp_border(width = 0)) %>%
    align(align = "center", part = "all") %>%
    align(j = 1, align = "left", part = "body") %>%
    bold(part = "header") %>%
    align(align = "left", part = "footer") %>%
    fontsize(size = 9, part = "footer") %>%
    hline_bottom(part = "body",   border = officer::fp_border(width = 1)) %>%
    hline_bottom(part = "footer", border = officer::fp_border(width = 0))
}

# ==============================================================================
# SECCIÓN 1: ¿CUÁNTOS HOGARES TIENEN MASCOTAS?---------------------------------
# Propósito: Justificar el tamaño y representatividad del universo de análisis.
# Si la proporción de hogares con mascota es pequeña, el análisis posterior
# debe interpretarse con cautela.
# ==============================================================================

# Tabla 1
tabla_mascota <- enaho_diseno %>%
  filter(!is.na(tiene_mascota_etiqueta)) %>%
  group_by(tiene_mascota_etiqueta) %>%
  summarise(Hogares    = survey_total(vartype = NULL),
            Porcentaje = survey_mean(vartype = NULL) * 100) %>%
  mutate(Hogares    = scales::comma(round(Hogares, 0)),
         Porcentaje = paste0(round(Porcentaje, 1), "%")) %>%
  rename(`Tenencia de mascota` = tiene_mascota_etiqueta,
         `Total (N)` = Hogares, `%` = Porcentaje)

ft_mascota <- formato_flextable(tabla_mascota,
                                "Tabla 1. Hogares según tenencia de mascotas, 2025")
print(ft_mascota)

# Gráfico 1
plot_mascota <- ggplot(
  enaho_explorar %>% filter(!is.na(tiene_mascota)),
  aes(x = tiene_mascota_etiqueta, weight = factor_s)) +
  geom_bar(fill = "#4A7C59", alpha = 0.85) +
  scale_y_continuous(labels = scales::comma) +
  labs(title   = "Gráfico 1. Hogares según tenencia de mascotas, 2025",
       x       = "Tenencia de mascota",
       y       = "Hogares (frecuencia poblacional)",
       caption = "Fuente: ENAHO 2025") +
  theme_minimal()
print(plot_mascota)

# ==============================================================================
# SECCIÓN 2: ¿QUÉ TIPO DE MASCOTAS TIENEN?------------------------------------
# Propósito: Verificar que hay suficientes casos en cada grupo (perro, gato,
# otra mascota) para que la comparación en la sección 4 sea estadísticamente
# válida. Si algún grupo tiene muy pocos casos, la comparación no sería robusta.
# ==============================================================================

# Tabla 2
tabla_tipo_mascota <- enaho_explorar %>%
  filter(tiene_mascota == TRUE) %>%
  select(conglome, estrato, factor_s,
         tiene_perro, tiene_gato, tiene_otra_mascota) %>%
  pivot_longer(cols = c(tiene_perro, tiene_gato, tiene_otra_mascota),
               names_to = "Tipo", values_to = "Tiene") %>%
  filter(Tiene == TRUE) %>%
  as_survey_design(ids = conglome, strata = estrato,
                   weights = factor_s, nest = TRUE) %>%
  group_by(Tipo) %>%
  summarise(Hogares = survey_total(vartype = NULL)) %>%
  mutate(
    Porcentaje = (Hogares / sum(enaho_explorar %>%
                                  filter(tiene_mascota == TRUE) %>%
                                  pull(factor_s), na.rm = TRUE)) * 100,
    Hogares    = scales::comma(round(Hogares, 0)),
    Porcentaje = paste0(round(Porcentaje, 1), "%"),
    Tipo = case_when(
      Tipo == "tiene_perro"        ~ "Perro",
      Tipo == "tiene_gato"         ~ "Gato",
      Tipo == "tiene_otra_mascota" ~ "Otra mascota"
    )
  ) %>%
  arrange(desc(parse_number(str_remove(Hogares, ",")))) %>%
  rename(`Tipo de mascota` = Tipo, `Hogares (N)` = Hogares, `%` = Porcentaje)

ft_tipo_mascota <- formato_flextable(tabla_tipo_mascota,
                                     "Tabla 2. Hogares con mascotas según tipo de animal, 2025")
print(ft_tipo_mascota)

# Gráfico 2
plot_tipo_mascota <- enaho_explorar %>%
  filter(tiene_mascota == TRUE) %>%
  select(factor_s, tiene_perro, tiene_gato, tiene_otra_mascota) %>%
  pivot_longer(cols = c(tiene_perro, tiene_gato, tiene_otra_mascota),
               names_to = "Tipo", values_to = "Tiene") %>%
  filter(Tiene == TRUE) %>%
  mutate(Tipo = case_when(
    Tipo == "tiene_perro"        ~ "Perro",
    Tipo == "tiene_gato"         ~ "Gato",
    Tipo == "tiene_otra_mascota" ~ "Otra mascota"
  )) %>%
  ggplot(aes(x = reorder(Tipo, -factor_s), weight = factor_s)) +
  geom_bar(fill = "#2E5B88", alpha = 0.85) +
  scale_y_continuous(labels = scales::comma) +
  labs(title   = "Gráfico 2. Hogares con mascotas según tipo de animal, 2025",
       x       = "Tipo de mascota",
       y       = "Hogares (frecuencia poblacional)",
       caption = "Fuente: ENAHO 2025") +
  theme_minimal()
print(plot_tipo_mascota)

# ==============================================================================
# SECCIÓN 3: ¿CÓMO SON LAS CONDICIONES DE VIVIENDA DE HOGARES CON MASCOTAS?---
# Propósito: Explorar la variabilidad individual de nbi1, nbi2 y nbi3.
# Una variable con poca variabilidad (ej. 99% en un valor) no aportaría
# información útil al índice. Esta sección justifica incluir las tres NBI.
# ==============================================================================

# Tabla 3: Las tres NBI en una sola tabla resumen
tabla_nbi <- enaho_diseno_mascotas %>%
  summarise(
    `NBI 1: Vivienda inadecuada`      = survey_mean(nbi1, vartype = NULL) * 100,
    `NBI 2: Hacinamiento`             = survey_mean(nbi2, vartype = NULL) * 100,
    `NBI 3: Sin servicios higiénicos` = survey_mean(nbi3, vartype = NULL) * 100
  ) %>%
  pivot_longer(everything(),
               names_to  = "Indicador NBI",
               values_to = "% Hogares con NBI insatisfecha") %>%
  mutate(`% Hogares con NBI insatisfecha` =
           paste0(round(`% Hogares con NBI insatisfecha`, 1), "%"))

ft_nbi <- formato_flextable(tabla_nbi,
                            "Tabla 3. Proporción de hogares con NBI insatisfecha, según indicador (hogares con mascotas), 2025")
print(ft_nbi)

# Tabla 4: Distribución detallada de cada NBI (0 y 1)
tabla_nbi_detalle <- enaho_diseno_mascotas %>%
  group_by(nbi1_etiqueta) %>%
  summarise(Hogares = survey_total(vartype = NULL),
            Porcentaje = survey_mean(vartype = NULL) * 100) %>%
  mutate(NBI = "NBI 1: Vivienda inadecuada",
         Hogares = scales::comma(round(Hogares, 0)),
         Porcentaje = paste0(round(Porcentaje, 1), "%")) %>%
  rename(Condicion = nbi1_etiqueta) %>%
  bind_rows(
    enaho_diseno_mascotas %>%
      group_by(nbi2_etiqueta) %>%
      summarise(Hogares = survey_total(vartype = NULL),
                Porcentaje = survey_mean(vartype = NULL) * 100) %>%
      mutate(NBI = "NBI 2: Hacinamiento",
             Hogares = scales::comma(round(Hogares, 0)),
             Porcentaje = paste0(round(Porcentaje, 1), "%")) %>%
      rename(Condicion = nbi2_etiqueta),
    enaho_diseno_mascotas %>%
      group_by(nbi3_etiqueta) %>%
      summarise(Hogares = survey_total(vartype = NULL),
                Porcentaje = survey_mean(vartype = NULL) * 100) %>%
      mutate(NBI = "NBI 3: Sin servicios higiénicos",
             Hogares = scales::comma(round(Hogares, 0)),
             Porcentaje = paste0(round(Porcentaje, 1), "%")) %>%
      rename(Condicion = nbi3_etiqueta)
  ) %>%
  select(NBI, Condicion, Hogares, Porcentaje) %>%
  rename(`Indicador NBI` = NBI, `Condición` = Condicion,
         `Total (N)` = Hogares, `%` = Porcentaje)

ft_nbi_detalle <- formato_flextable(tabla_nbi_detalle,
                                    "Tabla 4. Distribución de hogares con mascotas según condición de cada NBI, 2025")
print(ft_nbi_detalle)

# Gráfico 3: Las tres NBI juntas
plot_nbi <- enaho_explorar %>%
  filter(tiene_mascota == TRUE) %>%
  select(factor_s, nbi1, nbi2, nbi3) %>%
  pivot_longer(cols = c(nbi1, nbi2, nbi3),
               names_to = "NBI", values_to = "Valor") %>%
  mutate(
    NBI = case_when(
      NBI == "nbi1" ~ "NBI 1:\nVivienda inadecuada",
      NBI == "nbi2" ~ "NBI 2:\nHacinamiento",
      NBI == "nbi3" ~ "NBI 3:\nSin servicios higiénicos"
    ),
    Valor = factor(Valor, levels = c(0, 1),
                   labels = c("Satisfecha", "Insatisfecha"))
  ) %>%
  ggplot(aes(x = NBI, fill = Valor, weight = factor_s)) +
  geom_bar(position = "fill", alpha = 0.85) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("Satisfecha" = "#4575B4", "Insatisfecha" = "#D73027")) +
  labs(title   = "Gráfico 3. Condiciones de vivienda (NBI) en hogares con mascotas, 2025",
       x       = "Indicador NBI",
       y       = "Proporción de hogares",
       fill    = "Necesidad básica:",
       caption = "Fuente: ENAHO 2025") +
  theme_minimal() +
  theme(legend.position = "bottom")
print(plot_nbi)

# ==============================================================================
# SECCIÓN 4: ¿LAS CONDICIONES VARÍAN SEGÚN TIPO DE MASCOTA?-------------------
# Propósito: Identificar si existen diferencias en las condiciones de vivienda
# entre hogares con perro, gato u otra mascota. Si hay variación, justifica
# usar el tipo de mascota como variable de análisis en la clasificación.
# ==============================================================================

# Tabla 5: % de NBI insatisfecha según tipo de mascota
tabla_nbi_tipo <- enaho_explorar %>%
  filter(tiene_mascota == TRUE) %>%
  select(conglome, estrato, factor_s,
         tiene_perro, tiene_gato, tiene_otra_mascota,
         nbi1, nbi2, nbi3) %>%
  pivot_longer(cols = c(tiene_perro, tiene_gato, tiene_otra_mascota),
               names_to = "Tipo_mascota", values_to = "Tiene") %>%
  filter(Tiene == TRUE) %>%
  pivot_longer(cols = c(nbi1, nbi2, nbi3),
               names_to = "NBI", values_to = "Valor") %>%
  mutate(
    Tipo_mascota = case_when(
      Tipo_mascota == "tiene_perro"        ~ "Perro",
      Tipo_mascota == "tiene_gato"         ~ "Gato",
      Tipo_mascota == "tiene_otra_mascota" ~ "Otra mascota"
    ),
    NBI = case_when(
      NBI == "nbi1" ~ "NBI 1: Vivienda inadecuada",
      NBI == "nbi2" ~ "NBI 2: Hacinamiento",
      NBI == "nbi3" ~ "NBI 3: Sin servicios higiénicos"
    )
  ) %>%
  as_survey_design(ids = conglome, strata = estrato,
                   weights = factor_s, nest = TRUE) %>%
  group_by(Tipo_mascota, NBI) %>%
  summarise(Pct = survey_mean(Valor, vartype = NULL) * 100) %>%
  mutate(Pct = paste0(round(Pct, 1), "%")) %>%
  pivot_wider(names_from = NBI, values_from = Pct) %>%
  rename(`Tipo de mascota` = Tipo_mascota)

ft_nbi_tipo <- formato_flextable(tabla_nbi_tipo,
                                 "Tabla 5. % de hogares con NBI insatisfecha según tipo de mascota, 2025")
print(ft_nbi_tipo)

# Gráfico 4: NBI por tipo de mascota
plot_nbi_tipo <- enaho_explorar %>%
  filter(tiene_mascota == TRUE) %>%
  select(factor_s, tiene_perro, tiene_gato, tiene_otra_mascota,
         nbi1, nbi2, nbi3) %>%
  pivot_longer(cols = c(tiene_perro, tiene_gato, tiene_otra_mascota),
               names_to = "Tipo_mascota", values_to = "Tiene") %>%
  filter(Tiene == TRUE) %>%
  pivot_longer(cols = c(nbi1, nbi2, nbi3),
               names_to = "NBI", values_to = "Valor") %>%
  mutate(
    Tipo_mascota = case_when(
      Tipo_mascota == "tiene_perro"        ~ "Perro",
      Tipo_mascota == "tiene_gato"         ~ "Gato",
      Tipo_mascota == "tiene_otra_mascota" ~ "Otra mascota"
    ),
    NBI = case_when(
      NBI == "nbi1" ~ "NBI 1:\nVivienda inadecuada",
      NBI == "nbi2" ~ "NBI 2:\nHacinamiento",
      NBI == "nbi3" ~ "NBI 3:\nSin servicios higiénicos"
    ),
    Valor = factor(Valor, levels = c(0, 1),
                   labels = c("Satisfecha", "Insatisfecha"))
  ) %>%
  ggplot(aes(x = Tipo_mascota, fill = Valor, weight = factor_s)) +
  geom_bar(position = "fill", alpha = 0.85) +
  facet_wrap(~NBI) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("Satisfecha" = "#4575B4", "Insatisfecha" = "#D73027")) +
  labs(title   = "Gráfico 4. Condiciones de vivienda (NBI) según tipo de mascota, 2025",
       x       = "Tipo de mascota",
       y       = "Proporción de hogares",
       fill    = "Necesidad básica:",
       caption = "Fuente: ENAHO 2025 - Módulo 118.") +
  theme_minimal() +
  theme(legend.position = "bottom")
print(plot_nbi_tipo)


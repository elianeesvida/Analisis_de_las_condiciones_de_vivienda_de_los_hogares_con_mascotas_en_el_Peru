# ==============================================================================
# Proyecto:  Análisis de las condiciones de vivienda de los hogares con mascotas en el Perú
# Script: Acondicionamiento
# Autor: Eliane Caceres
# Fecha: 03-07-2026
# Objetivo: Acondicionar la base de datos de mascotas (Carga, Selección,
#           Renombrado, Diagnóstico y Tratamiento de NAs).
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. CONFIGURACIÓN DEL ENTORNO--------------------------------------------------
# ------------------------------------------------------------------------------
library(tidyverse)
library(arrow)
library(janitor)
library(naniar)
renv::snapshot()

# ------------------------------------------------------------------------------
# 1. CARGA Y SELECCIÓN DE VARIABLES
# ------------------------------------------------------------------------------
# Leemos la base que consolidamos en el script anterior en formato parquet.
enaho_2025_mascotas <- read_parquet("datos/procesados/enaho_2025_210626.parquet")


# Filtramos al universo válido: solo hogares que respondieron el módulo 118.
# OJO: Los NAs en tiene_mascota NO significan "sin mascota",
# sino hogares no elegibles para la sub-muestra del módulo 118.
enaho_seleccion <- enaho_2025_mascotas %>%
  filter(!is.na(tiene_mascota)) %>%
  select(
    # Llaves de integración
    conglome, vivienda, hogar,
    ubigeo, dominio, estrato,
    
    # Factor de expansión de la sub-muestra de mascotas (módulo 118)
    # OJO: se usa factor_s y NO factor07, porque la unidad de análisis
    # es la sub-muestra del módulo 118, no la muestra completa del módulo 100.
    factor_s,
    
    # Tenencia de mascotas (módulo 118)
    tiene_mascota, tiene_perro, tiene_gato, tiene_otra_mascota,
    
    # Condiciones de vivienda - NBI (módulo 100)
    nbi1,   # Vivienda inadecuada
    nbi2,   # Hacinamiento
    nbi3,   # Sin servicios higiénicos
  )

# Inspección rápida
dim(enaho_seleccion)
names(enaho_seleccion)
glimpse(enaho_seleccion)

# ------------------------------------------------------------------------------
# 2. DIAGNÓSTICO DE NAs Y REPORTE-----------------------------------------------
# ------------------------------------------------------------------------------

# 2.1 Visualización Gráfica (naniar)
grafico_nas <- gg_miss_var(enaho_seleccion, show_pct = TRUE) +
  labs(
    title    = "Porcentaje de Valores Perdidos (NAs) por Variable",
    subtitle = "Proyecto:Análisis de las condiciones de vivienda de los hogares con mascotas en el Perú",
    y = "% de Valores Perdidos",
    x = "Variables"
  ) +
  theme_minimal()

print(grafico_nas)

ggsave("outputs/Grafico_NAs_Mascotas.png", plot = grafico_nas,
       width = 8, height = 6, bg = "white")

# 2.2 Reporte Tabular
reporte_nas <- enaho_seleccion %>%
  summarise(across(everything(), ~ round(sum(is.na(.)) / n() * 100, 2))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "porcentaje_na") %>%
  arrange(desc(porcentaje_na))

write_csv(reporte_nas, "outputs/Reporte_Datos_Perdidos_Mascotas.csv")

# ------------------------------------------------------------------------------
# 3. DIAGNÓSTICO PREVIO DE NAs EN VARIABLES NBI---------------------------------
# ------------------------------------------------------------------------------
table(enaho_seleccion$nbi1, useNA = "ifany")
table(enaho_seleccion$nbi2, useNA = "ifany")
table(enaho_seleccion$nbi3, useNA = "ifany")

# RESULTADO: Las tres variables NBI presentan únicamente valores 0 y 1,
# sin ningún NA. Los NAs que existían originalmente no representaban
# datos perdidos, sino hogares que no fueron seleccionados para el
# módulo 118, al ser este una sub-muestra aplicada por primera vez
# en el segundo semestre de 2025. Al restringir el universo de análisis
# a los hogares elegibles (filter(!is.na(tiene_mascota))), estos casos
# fueron excluidos correctamente sin necesidad de imputación.
# DECISIÓN: No se requiere ningún tratamiento de NAs para nbi1, nbi2 y nbi3.


# ------------------------------------------------------------------------------
# 5. EXPORTACIÓN DE LA BASE ACONDICIONADA---------------------------------------
# ------------------------------------------------------------------------------
write_parquet(enaho_seleccion, "datos/procesados/enaho_mascotas_acondicionada_030726.parquet")



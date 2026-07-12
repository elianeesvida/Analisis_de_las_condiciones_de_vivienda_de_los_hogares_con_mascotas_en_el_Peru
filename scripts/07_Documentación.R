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

# ==============================================================================
# 3. DOCUMENTACIÓN DE DECISIONES METODOLÓGICAS---------------------------------
# ==============================================================================
dict_metadata <- list(
  nbi1 = "Variable precalculada por el INEI en el Módulo 100. Toma el valor 0 (necesidad satisfecha) o 1 (necesidad insatisfecha). Indica si la vivienda tiene características físicas inadecuadas (paredes, pisos o techo de material precario).",
  
  nbi2 = "Variable precalculada por el INEI en el Módulo 100. Toma el valor 0 (necesidad satisfecha) o 1 (necesidad insatisfecha). Indica si el hogar se encuentra en condición de hacinamiento (más de 3.4 personas por habitación).",
  
  nbi3 = "Variable precalculada por el INEI en el Módulo 100. Toma el valor 0 (necesidad satisfecha) o 1 (necesidad insatisfecha). Indica si la vivienda carece de servicios higiénicos de ningún tipo.",
  
  tiene_mascota = "Variable construida a partir del Módulo 118. Toma el valor TRUE si algún miembro del hogar respondió '1' (Sí) en la pregunta P118B. Los NAs en esta variable representan hogares no elegibles para la sub-muestra del módulo 118, no hogares sin mascota.",
  
  area = "Variable construida a partir del estrato geográfico. Los estratos 1 a 6 corresponden a centros poblados urbanos de distintos tamaños (de 500 a más de 500,000 habitantes). Los estratos 7 y 8 corresponden a Áreas de Empadronamiento Rural (AER) Compuesto y Simple, respectivamente. Fuente: INEI.",
  
  factor_s = "Factor de expansión propio de la sub-muestra del módulo 118. Se utiliza en lugar del factor07 del módulo 100 porque la unidad de análisis es la sub-muestra de mascotas, que tiene un diseño muestral distinto al de la muestra principal de la ENAHO.",
  
  indice_cv = "Índice de Calidad de Vivienda construido mediante la suma simple de nbi1 + nbi2 + nbi3. Rango: 0 (ninguna NBI insatisfecha) a 3 (las tres NBI insatisfechas). Metodología: INEI (suma de necesidades básicas insatisfechas). Justificación: en el EDA se verificó que las tres variables presentan variabilidad suficiente (nbi1=5.4%, nbi2=3.2%, nbi3=4.4% insatisfechas), lo que valida su inclusión en el índice.",
  
  categoria_cv = "Categorización ordinal del Índice de Calidad de Vivienda. Combina dos referentes metodológicos: (1) el INEI, que define como pobre por NBI a todo hogar con al menos una necesidad básica insatisfecha; y (2) la lógica de clasificación ordinal propuesta por Ponce Sernicharo (2006). Categorías: Buena calidad (0 NBI insatisfechas), Mala calidad (1 NBI insatisfecha) y Muy mala calidad (2 o más NBI insatisfechas). Referencia: Ponce Sernicharo, G. (2006). Construcción de un Índice de Calidad de la Vivienda. En R. Coulomb (coord.), La vivienda en México: Escribiendo el futuro. México: Cámara de Diputados / CONAFOVI / UAM. pp. 169-186.",
  
  tipologia_mascota = "Clasificación MECE (Mutuamente Excluyente, Colectivamente Exhaustiva) de los hogares según el tipo de mascota que tienen. Se construye a partir del cruce de las variables tiene_perro, tiene_gato y tiene_otra_mascota. Categorías: Solo perro, Solo gato, Solo otra mascota, Perro y gato, Perro y otra mascota, Gato y otra mascota, y Perro gato y otra mascota."
)

# Aplicamos las descripciones a las columnas correspondientes
for (var in names(dict_metadata)) {
  attr(enaho_codebook[[var]], "description") <- dict_metadata[[var]]
}

# Metadatos a nivel de estudio
metadata(enaho_codebook)$name <- "Base de Datos Analítica - Calidad de Vivienda de Hogares con Mascotas en el Perú, 2025"
metadata(enaho_codebook)$description <- "Sub-muestra de la Encuesta Nacional de Hogares (ENAHO 2025) restringida a hogares que respondieron el módulo 118 (Tenencia de mascotas), aplicado entre julio y diciembre de 2025."
metadata(enaho_codebook)$creator <- "Eliane Caceres"

# Guardamos la base con los metadatos
write_parquet(enaho_codebook,
              here("datos", "procesados", "enaho_mascotas_final_030726.parquet"))


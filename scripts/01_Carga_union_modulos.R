#================================================================================
#Proyecto: Mascotas ENAHO 2025
#Script: Cargar los módulos y hacer los joins
#Autor: Eliane Caceres
#Fecha: 21-06-2026
#===============================================================================

#1.Carga de librerías---------------------------
library(rio)
library(tidyverse)
library(janitor)
library(readr)
renv::snapshot()

#2. Importar datos--------------------
mod100 <- import(
  "datos/crudos/Enaho01-2025-100.csv",
  encoding = "Latin-1", sep = ";", dec = ",",
  na.strings = c("", " ", "NA"),
  colClasses = c(CONGLOME = "character", VIVIENDA = "character",
                 HOGAR = "character", UBIGEO = "character")
)

mod118 <- import(
  "datos/crudos/Enaho01-2025-118.csv",
  encoding = "Latin-1", sep = ";", dec = ",",
  na.strings = c("", " ", "NA"),
  colClasses = c(CONGLOME = "character", VIVIENDA = "character",
                 HOGAR = "character", UBIGEO = "character")
)

#3. Limpieza de nombres de columnas--------------------
mod100 <- mod100 %>% clean_names()
mod118 <- mod118 %>% clean_names()

#4. Filtro de cobertura temporal--------------------
#mod118 solo se aplicó de julio a diciembre 2025. Como el proyecto es
#sobre mascotas, restringimos mod100 al mismo periodo,
#para que el cruce represente un mismo momento de recolección de datos
#en vez de mezclar hogares que nunca pudieron tener esa información.
mod100 <- mod100 %>% filter(mes >= "7")

#5. Preparación del módulo de mascotas--------------------
#El módulo 118 tiene hasta 3 filas por hogar (perro, gato, otro);
#antes de unirlo con mod100 hay que resumirlo a una sola fila por hogar
mascotas_hogar <- mod118 %>%
  group_by(conglome, vivienda, hogar) %>%
  summarise(
    tiene_perro        = any(p118a1 == 1 & p118b == 1, na.rm = TRUE),
    tiene_gato         = any(p118a1 == 2 & p118b == 1, na.rm = TRUE),
    tiene_otra_mascota = any(p118a1 == 3 & p118b == 1, na.rm = TRUE),
    tiene_mascota      = any(p118b == 1, na.rm = TRUE),
    .groups = "drop"
  )

#6. Unión de las bases----------------------------------
enaho_2025_mascotas <- mod100 %>%
  left_join(mascotas_hogar, by = c("conglome", "vivienda", "hogar"))

#Aun dentro de julio-diciembre, el módulo 118 fue una sub-muestra,
#así que algunos hogares seguirán con NA: representan hogares que
#no fueron seleccionados para esa sub-muestra, no "sin mascota"
sum(is.na(enaho_2025_mascotas$tiene_mascota))

#7. Exportación de la base de datos creada------------------------

install.packages("arrow")
library(arrow)
renv::snapshot()

write_parquet(enaho_2025_mascotas, "datos/procesados/enaho_2025_210626.parquet")

renv::snapshot()




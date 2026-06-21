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
mod100 <- import("datos/crudos/Enaho01-2025-100.csv", encoding = "Latin-1")
mod118 <- import("datos/crudos/Enaho01-2025-118.csv", encoding = "Latin-1")

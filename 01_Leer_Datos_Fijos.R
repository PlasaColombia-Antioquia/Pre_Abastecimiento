################################################################################
#Proyecto FAO
#Procesamiento datos SIPSA
################################################################################
#Autores: Juliana Lalinde, Laura Quintero
#Fecha de creacion: 11/02/2024
#Fecha de ultima modificacion: 07/02/2024
################################################################################

# Cargar las bibliotecas necesarias
pacman::p_load(readr,readxl,dplyr,glue,openxlsx,foreign,janitor,plyr,writexl)
pacman::p_load(readr,lubridate,dplyr,ggplot2,zoo,mvoutlier)
options(scipen = 999)



### ABASTECIMIENTO - MICRODATOS ################################################
# Limpiar el entorno de trabajo
rm(list=ls())
source("aux_functions.R")

#### 01 - Write --> Open Data 
lapply(c(seq(2013,2023,1)),get_yr)

#### 02 - Crear bases de datos por producto
ds <- do.call(rbind,lapply(c(2013:2023), rd_ds))

ds <- ds %>% mutate(grupo_short=recode(grupo_alimento,
                "GRANOS Y CEREALES" = "GRANOS"  ,
                "LACTEOS Y HUEVOS" = "HUEVOS-LACTEOS" ,
                "PESCADOS Y MARISCOS" = "PESCADO-MARISCOS"  ,
                "TUBERCULOS, RAICES Y PLATANOS" = "TUBERCULOS",
                "VERDURAS Y HORTALIZAS"= "VERDURAS"  ))

lapply(unique(ds$grupo_short),wr_ds,ds=ds)

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
  pacman::p_load(readr,lubridate,dplyr,ggplot2,zoo,mvoutlier,future.apply,future,tidyr)
  pacman::p_load(performance) # Outliers check_outliers()
  # devtools::install_github("brunocarlin/tidy.outliers")
  #install.packages("performance")
  options(scipen = 999)

  ## Functions
  rm(list=ls())
  source("aux_functions.R")

  ####  Set Parallele computing
    plan(multisession) ## Run in parallel on local computer
    # Increase the maximum allowed size to, for example, 2 GB
    options(future.globals.maxSize = 2 * 1024 * 1024^2)

grp_alim <- c("PESCADOS","HUEVOS-LACTEOS","GRANOS","CARNES","PROCESADOS","TUBERCULOS","FRUTAS","VERDURAS")

# Aquí se filtra solo para Antioquia
future_lapply(grp_alim,alimen_cleaned)
 

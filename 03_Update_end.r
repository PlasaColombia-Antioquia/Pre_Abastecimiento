################################################################################
#Proyecto FAO
#Procesamiento datos SIPSA
################################################################################
#Autores: Juliana Lalinde, Laura Quintero
#Fecha de creacion: 11/02/2024
#Fecha de ultima modificacion: 07/02/2024
################################################################################

# Cargar las bibliotecas necesarias
pacman::p_load(readr,readxl,dplyr,glue,openxlsx,foreign,janitor,plyr,dplyr)
pacman::p_load(readr,lubridate,dplyr,ggplot2,zoo)

### ABASTECIMIENTO - MICRODATOS ################################################
# Limpiar el entorno de trabajo
rm(list=ls())
source("aux_functions.R")
grp_alim <- c("PESCADOS","HUEVOS-LACTEOS","GRANOS","CARNES","PROCESADOS","TUBERCULOS","FRUTAS","VERDURAS")


## Actualizar 
download.file(url = "https://www.dane.gov.co/files/operaciones/SIPSA/anex-Microdato-abastecimiento-2024.xlsx", 
                destfile = "Input/anex-Microdato-abastecimiento-2024.xlsx", mode="wb")

# Update date
get_yr(2024)
update <- rd_ds(2024) %>% mutate(grupo_short=recode(grupo_alimento,
                "GRANOS Y CEREALES" = "GRANOS"  ,
                "LACTEOS Y HUEVOS" = "HUEVOS-LACTEOS" ,
                "PESCADOS Y MARISCOS" = "PESCADO-MARISCOS"  ,
                "TUBERCULOS, RAICES Y PLATANOS" = "TUBERCULOS",
                "VERDURAS Y HORTALIZAS"= "VERDURAS"  ))

    ### Information - Updated procuts
    lapply(unique(update$grupo_short),
                    wr_ds_update,
                    ds=update)

    ## Final data
    lapply(grp_alim,merge_end)

    ## Base de datos final
    out_add <- readRDS(glue("Output/final_products/","PESCADOS",".rds"))
    for (g in grp_alim[2:8]) {
        out_add <- rbind(out_add,readRDS(glue("Output/final_products/",g,".rds")))
    }
    saveRDS(out_add, paste0("Output/base_abastecimiento_no_outliers.rds"))
    
 
    
# HASTA AQUI        
    

  # Agrupamos la base a nivel mensual (sumamos los kg - meses)
    
    fecha <- as.Date(out_add$fecha)
    out_add$mes_y_ano <- format(fecha, "%Y-%m")
    
    out_add2 <- out_add %>% mutate(cantidad_kg=as.numeric(cantidad_kg))%>%tidyr::drop_na()%>%
      dplyr::group_by(codigo_mpio_destino, codigo_mpio_origen, mpio_destino, depto_origen,mpio_origen,grupo_alimento,alimento,mes_y_ano)%>%
      dplyr::summarise(suma_kg = sum((cantidad_kg), na.rm = TRUE)) %>%
      ungroup()
    
  # Exportamos la base de datos mensual. Teniendo outliers
    saveRDS(out_add2, "Output/base_abastecimiento_mensual_no_outliers.rds")
    
    
    
    
    
    
    

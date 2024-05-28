#Proyecto FAO
#Procesamiento datos SIPSA
################################################################################
#Autores: Juliana Lalinde, Laura Quintero, German Angulo
#Fecha de creacion: 13/02/2024
#Fecha de ultima modificacion: 13/02/2024
################################################################################
# Paquetes 
################################################################################

 options(scipen = 999)
################################################################################

# Cargar la base de municipios 
    municipios <- read.csv("Input/base_codigo_municipios.csv")
    municipios <- municipios[,c("Municipio","codigo_mpio","Departamento")] 
    names(municipios) <- c("mpio_destino","codigo_mpio_destino","Departamento")

# Alimentos
  sipsa_id <- read_excel("Input/Equivalencias_Codigos_Alimentos.xlsx",sheet="SISPSA_A",range=cell_cols("A:C"))
  names(sipsa_id) <- c("alimento","alimento_grupo","cod_sipsa")


#### 01 - Clean data 
################################################################################

clean_abas <- function(yr,data) {
    ## Esta función limpia los datos y los estandizariza 

    #Eliminar las filas extra de que pueda tener la tabla por formato
    data <- data[which(Reduce(`|`, lapply(data, grepl, pattern = "Cuidad, Mercado Mayorista"))):nrow(data),]

    #Cambiar nombres de columnas
    colnames(data) <- data[1,]
    data <- data[2:nrow(data),]

    #Eliminar columnas de N/A
    data <- data[,!names(data) %in% c("NA")]

    #Convertir el formato de las fechas
    if(yr == 2020){ # nolint
        data$Fecha <- as.Date(data$Fecha, format = "%d/%m/%y")
    } else {
        data$Fecha <- excel_numeric_to_date(as.numeric(data$Fecha))
    }

    #Organizar número de departamento y municipio
    data$`Código Departamento` <- substr(data$`Código Departamento`,2,3)
    data$`Código Municipio` <- substr(data$`Código Municipio`,2,6)
    
    #Separar municipio y mercado mayorista de destino
    data <- cbind(sub('.*,', '', data$`Cuidad, Mercado Mayorista`),data)
    data$`Cuidad, Mercado Mayorista` <- sub(',.*', '', data$`Cuidad, Mercado Mayorista`)

    #Organizar nombres de columnas
    colnames(data) <- c("mercado_destino","mpio_destino","fecha","codigo_depto_origen","codigo_mpio_origen","depto_origen","mpio_origen","grupo_alimento","alimento","cantidad_kg")

    # Organizar la información de departamento
        data <- data %>% mutate(mpio_destino_dpto=mpio_destino)

        data$mpio_destino <- sapply(data $mpio_destino_dpto, 
            function(x) {
                if (grepl(" \\(", x)) {
                    return(strsplit(x, " \\(")[[1]][1])
                } else {
                    return(x)
                }
        })
        

    # Organizar información municipios
     data$mpio_destino <- ifelse(data$mpio_destino == "Cartagena", "Cartagena de Indias", data$mpio_destino )

     data <- merge(data,municipios, by = "mpio_destino", all.x = TRUE)

    data <- data %>%filter(codigo_mpio_destino != 5059)

      
      data <- na.omit(data)

      return(data)
}

### 02 - Open Data SIPSA
################## 

get_yr <- function(yr) {
    ds <- c()
        ## Datos están por semestre
        for(half in 1:2) {
            ### Diferencias entre los datos
            if(yr == 2022) {
                data <- read_excel(paste0("Input/microdato-abastecimiento-2022.xlsx"),sheet = paste0("2.",half))
            } else if (yr == 2023) {
                data <- read_excel(paste0("Input/anex-SIPSAbastecimiento-Microdatos-2023.xlsx"),sheet = paste0("2.",half))
            } else if (yr == 2024) {
                data <- read_excel(paste0("Input/anex-Microdato-abastecimiento-2024.xlsx"),sheet = paste0("2.",half))%>%
                select(-"...8")
            } else {
                data <- read_excel(paste0("Input/microdato-abastecimiento-",yr,".xlsx"),sheet = paste0("1.",half))
        }

        #### clean data 
        ds <- rbind.fill(ds,clean_abas(yr,data))

        }

    ### Informacion
      saveRDS(ds, paste0("Output/raw_years/raw_abs_",yr,".rds"))

}

### 03 -  Contruir base de datos por cultivo
################## 

rd_ds <- function(yr) {
    return(readRDS(glue("Output/raw_years/raw_abs_",yr,".rds")))
}

wr_ds <- function(gr,ds) {
    
    ### Information 
    ds_out <- ds[ds$grupo_short==gr,]

    ### Write
    saveRDS(ds_out, paste0("Output/raw_products/",gr,".rds"))

}

wr_ds_update <- function(gr,ds) {
    
    ### Information 
    ds_out <- ds[ds$grupo_short==gr,]

    ### Write
    saveRDS(ds_out, paste0("Output/update_products/",gr,".rds"))

}

### 04 - Limpieza de los datos
##################

alimen_cleaned <- function(gr) {
    ### Read DataSet
    ds_out <- readRDS(glue("Output/raw_products/",gr,".rds"))
    ds_out <- ds_out %>% mutate(cantidad_kg=as.numeric(cantidad_kg))

    ### Datos antioquia
    #ds_out <- ds_out[(ds_out$depto_origen=="ANTIOQUIA" | ds_out$mpio_destino == "Medellín"),]
    
    ### Routes Information
    routes <- ds_out[!duplicated(ds_out[c("mpio_origen","mpio_destino")]),
    c("mpio_origen","mpio_destino")] 

    ### Estimación
        ### Get the route
   
     ds_out <- do.call(rbind,lapply(c(1:nrow(routes)), 
                                routes_outliers,
                                ds_out=ds_out,
                                routes=routes))

    ### Write
    saveRDS(ds_out, paste0("Output/cleaned_products/",gr,".rds"))

    print(paste0(gr," -- LISTO !"))

}

### 04 - RUTAS
##################
    
routes_outliers <- function(i,ds_out,routes) {

    rt1 <- routes[i,]
    #print(i)
    #print(rt1)

    ### Get only the data
    ds_out <- ds_out %>% drop_na(alimento)
    ds_out1 <- ds_out[(ds_out$mpio_origen==rt1$mpio_origen) &
                (ds_out$mpio_destino==rt1$mpio_destino),]
    alim <- ds_out1[!duplicated(ds_out1$alimento),c("alimento")]

    ### Return data base 
    return(do.call(rbind,lapply(alim, outliers_alim,ds_out1=ds_out1)))

}
 

### 04 - Remover Outliers en Alimentos
##################

outliers_alim <- function(al,ds_out1) {
    #print(alim)
    
    #print(ds_out1)
    ds_out2 <- ds_out1[ds_out1$alimento==al,]
    #print(nrow(ds_out2))

   if (nrow(ds_out2)>2) {
    outliers_list <- check_outliers(ds_out2$cantidad_kg,
                                method = "zscore",
                                threshold = 2) # Find outliers
    as.numeric(outliers_list)
    out <- ds_out2[!outliers_list, ]
   } else {
    out <- ds_out2
   }
    
    ### Data Base
    return(out)
}

### 05 - Merge data final
##################

merge_end <- function(gr) {
    cleaned <- readRDS(glue("Output/cleaned_products/",gr,".rds"))
    new <- readRDS(glue("Output/update_products/",gr,".rds"))

    end <- rbind(cleaned,new)

    saveRDS(end, paste0("Output/final_products/",gr,".rds"))

}

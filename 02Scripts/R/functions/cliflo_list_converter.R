
###################################
# R source code file used to convert a cliflo list dataset to data.table depending on data type
# written by Jian liu
# Depended on data.table package
###################################

list_converter <- function(cf.datalist){
  require(data.table)
  for (i in seq_along(cf.datalist)) {
    dt <- as.data.table(cf.datalist[[i]],stringsAsFactors = F)
    colnames(dt) <- gsub(pattern = "\\(|\\/","_",colnames(dt))
    colnames(dt) <- gsub(pattern = "\\)","",colnames(dt))
    
    dt <- dt[,Date:= as.Date(lubridate::ymd_hms(Date_local))]
    assign(paste0("dt_",cf.datalist[[i]]@dt_name, 
                  gsub("\\D","",dt$Date[1]),"to",
                  gsub("\\D","", max(dt$Date, na.rm = TRUE))),
           value = dt,envir = .GlobalEnv)
  }
}

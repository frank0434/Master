# Initial parameter values 
# par = c(0.005, 0.0005, 10)
# KL_layers = 22

# Edit fun
APSIMEditFun <- function(par, nodes = slurpnodes){
  no.ofPara = length(par)
  id = paste0(par, collapse = '_')
  f = file(paste0(apsimx_sims_dir,"temp", id, ".txt"), "w")
  for(i in seq_len(no.ofPara)){
    line = paste0(slurpnodes[i] , par[i])
    cat(line, "\r",
        file = f, 
        append = TRUE)
  }
  # Close the file and clean it from memory 
  close(f)
  rm(f)
  gc()
}
# Run fun 
APSIMRun = function(par)
{
  # Create a new name for the apsimx file 
  id <- paste0(par, collapse = '_')
  # Create a new name for the apsimx file 
  newname = paste0(apsimx_sims_dir, 'temp', id, ".apsimx")
  
  # Copy base apsimx file to its new name 
  system(paste("cp", apsimx_file, newname))
  
  # Modify the apsimx file 
  system(paste(apsimx, newname, apsimx_flag, 
               paste0(apsimx_sims_dir,"temp", id, ".txt")))
  
  # Execute the new apsimx file 
  system(paste(apsimx, newname, 
               "/NumberOfProcessors:8"))
  
}
library(RSQLite)

cost.function <- function(par, obspara = "SWC"){
  id <- paste0(par, collapse = '_')
  print(par)
  APSIMEditFun(par)
  APSIMRun(par)
  db <- RSQLite::dbConnect(RSQLite::SQLite(),
                           paste0(apsimx_sims_dir, 'temp', id,'.db'))
  
  
  PredictedObserved <-   RSQLite::dbReadTable(db,"PredictedObserved")
  
  # Generate multiple cost depends on user input of observation variables 
  no.ofobspara = length(obspara)
  l = vector("list", length = no.ofobspara)
  names(l) = obspara
  for (i in seq_len(no.ofobspara)){
    pre_col = paste0("Predicted.", obspara[i])
    obs_col = paste0("Observed.", obspara[i])
    l[[i]] = sum(na.omit(PredictedObserved[[pre_col]]- 
                           PredictedObserved[[obs_col]])^2)
  }
  
  totalCost = 0 
  totalCost = sum(unlist(l))
  
  RSQLite::dbDisconnect(db)
  
  rm(db)
  gc()
  
  system(paste("rm", paste0(apsimx_sims_dir, "temp", id, "*")))
  
  return(totalCost)
}
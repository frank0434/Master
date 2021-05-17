
# par <- c(3.961847,29.046383,37.934329,21.104493)
# Edit fun
APSIMEditFun <- function(par, nodes = editNodes){
  no.ofPara = length(par)
  id = paste0(abs(round(par,idLength)), collapse = '_')
  
  f = file(paste0(apsimx_sims_dir,"temp", id, ".txt"), "w")
  
  for(i in seq_len(no.ofPara)){
    line = paste0(nodes[i] , par[i])
    cat(line, "\r",
        sep ="\r",
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
  
  id = paste0(abs(round(par,idLength)), collapse = '_')
  # Create a new name for the apsimx file 
  newname = paste0(apsimx_sims_dir, 'temp', id, ".apsimx")
  
  # Copy base apsimx file to its new name 
  system(paste("cp", apsimx_file, newname))
  
  # Modify the apsimx file 
  system(paste(apsimx, newname, apsimx_flag, 
               paste0(apsimx_sims_dir,"temp", id, ".txt")))
  
  # Execute the new apsimx file 
  system(paste(apsimx, newname, "/NumberOfProcessors:8"))
  
}

library(RSQLite)


cost.function <- function(par, obspara){

    id = paste0(abs(round(par,idLength)), collapse = '_')
  print(par)
  
  APSIMEditFun(par)
  
  APSIMRun(par)
  
  # make(plan)
  
  
  totalCost = 0 
  
  if (file.exists(paste0(apsimx_sims_dir, 'temp', id, '.db')))
  {
    db <- RSQLite::dbConnect(RSQLite::SQLite(),
                             paste0(apsimx_sims_dir, 'temp', id,'.db'))
    
    if("PredictedObserved" %in% dbListTables(db)) 
    {
    PredictedObserved <-   RSQLite::dbReadTable(db,"PredictedObserved")
    
    no.ofobspara = length(obspara)
    l = vector("list", length = no.ofobspara)
    names(l) = obspara
    
    for (i in seq_len(no.ofobspara)){
      pre_col = paste0("Predicted.", obspara[i])
      obs_col = paste0("Observed.", obspara[i])
      
      if(length(na.omit(PredictedObserved[[pre_col]]))> 1 &&
         length(na.omit(PredictedObserved[[obs_col]]))> 1)
      {
        l[[i]] = sum(na.omit(PredictedObserved[[pre_col]]- 
                             PredictedObserved[[obs_col]])^2)  
      
      } else {totalCost = 1e6;}
      
    }
    
    totalCost = sum(unlist(l))
    RSQLite::dbDisconnect(db)
    rm(db)
    gc()
    
  } else {totalCost = 1e6;}
  
  } else {totalCost = 1e6;}
    
  if(totalCost < 1)
    totalCost = 1e6
  
  # Generate multiple cost depends on user input of observation variables 
  # obspara = "BudBurstDAWS"

  system(paste("rm", paste0(apsimx_sims_dir, "temp", id, "*")))
  
  return(totalCost)
}

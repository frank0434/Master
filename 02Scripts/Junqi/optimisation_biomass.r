
library(RSQLite)
# Edit fun
APSIMEditFun <- function(par, nodes = editNodes, id, index){
  no.ofPara = length(par)
  # id = paste0(abs(round(par,idLength)), collapse = '_')
  if(index == 1) {
  f = file(paste0(apsimx_sims_dir,"temp", id, ".txt"), "w")
  
  for(i in seq_len(no.ofPara)){
    line = paste0(nodes[i] , par[i])
    cat(line, "\r",
        sep ="\r",
        file = f, 
        append = TRUE)
  }
  #structural demand
 Cordon.Str <- '.Simulations.Replacements.Grapevine.Cordon.DMDemandPriorityFactors.Structural.FixedValue = '
 Trunk.Str <-  '.Simulations.Replacements.Grapevine.Trunk.DMDemandPriorityFactors.Structural.FixedValue = '
 Cordon.Str.Target <-  paste0(Cordon.Str, par[6])
 Trunk.Str.Target <-   paste0(Trunk.Str, par[6])
 
 cordon.juv <- '.Simulations.Replacements.Grapevine.Cordon.DMDemandPriorityFactors.Storage.Juvenile.Constant.FixedValue = '
 trunk.juv <- '.Simulations.Replacements.Grapevine.Trunk.DMDemandPriorityFactors.Storage.Juvenile.Constant.FixedValue = '
 cordon.juv.Target <-  paste0(cordon.juv, par[7])
 trunk.juv.Target <-   paste0(trunk.juv, par[7])
 
 cordon.rep <-  '.Simulations.Replacements.Grapevine.Cordon.DMDemandPriorityFactors.Storage.Reproductive.Constant.FixedValue = '
 trunk.rep <-  '.Simulations.Replacements.Grapevine.Trunk.DMDemandPriorityFactors.Storage.Reproductive.Constant.FixedValue = '
  
 cordon.rep.Target <-  paste0(cordon.rep, par[8])
 trunk.rep.Target <-   paste0(trunk.rep, par[8])
 
 cat(Cordon.Str.Target, "\r",
     Trunk.Str.Target, "\r",
     cordon.juv.Target, "\r",
     trunk.juv.Target, "\r",
     cordon.rep.Target, "\r",
     trunk.rep.Target, "\r",
     
     sep ="\r",
     file = f, 
     append = TRUE)
  
  
  # Close the file and clean it from memory 
  close(f)
  rm(f)
  gc()
  
  index = index +1;
  return(index)
  }
 
}
# Run fun 
APSIMRun <-  function(par, id, index)
{
  # Create a new name for the apsimx file 
  if(index == 2) {

  # id = paste0(abs(round(par,idLength)), collapse = '_')
  # Create a new name for the apsimx file 
  newname = paste0(apsimx_sims_dir, 'temp', id, ".apsimx")
  
  # Copy base apsimx file to its new name 
  system(paste("cp", apsimx_file, newname))
  
  # Modify the apsimx file 
  system(paste(apsimx, newname, apsimx_flag, 
               paste0(apsimx_sims_dir,"temp", id, ".txt")))
  
  # Execute the new apsimx file 
  system(paste(apsimx, newname, "/NumberOfProcessors:8"))
  
  index = index +1;
  return(index)
  }
}

#likelihood function 
  llik = function(x, obs){
    m = obs;   #mean of the observed points
    s = 0.1* obs;#assume 0.1 of the observed value
    n=length(x)
    # log of the normal likelihood
    # -n/2 * log(2*pi*s^2) + (-1/(2*s^2)) * sum((x-m)^2)
    ll = -(n/2)*(log(2*pi*s^2)) + (-1/(2*s^2)) * (x-m)^2
    
    # return the negative to maximize rather than minimize
    return(-sum(ll))
  }

    
calcCost <- function(id, obspara, index) 
{
  if(index == 3) {

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
        # i = 1
        pre_col = paste0("Predicted.", obspara[i])
        obs_col = paste0("Observed.", obspara[i])
        
        if(length(na.omit(PredictedObserved[[pre_col]]))> 1 &&
           length(na.omit(PredictedObserved[[obs_col]]))> 1)
        {
         
         intm <- na.omit(data.frame(sim = PredictedObserved[[pre_col]],
                                    obs = PredictedObserved[[obs_col]]))
         
         l[[i]] <- llik(intm[,1], intm[,2])  
           
         # l[[i]] = sum(na.omit(PredictedObserved[[pre_col]]- 
         #                         PredictedObserved[[obs_col]])^2)  
          
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
    
  }
  
  return(totalCost)
}



cost.function <- function(par, obspara){
  # par = 25
  # par <- c(0.838874,0.878763,0.940613,0.104054,    1.562999,    0.479789,    0.956549,    0.600151)
  id = paste0(abs(round(par,idLength)), collapse = '_')

  index1 = 1
  index2 = APSIMEditFun(par, editNodes, id, index1)
  index3 = APSIMRun(par, id, index2)
  
  totalCost = calcCost(id, obspara, index3)
  
  system(paste("rm", paste0(apsimx_sims_dir, "temp", id, "*")))
  
  index1 = 1
  return(totalCost)
  
}















































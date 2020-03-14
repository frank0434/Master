paras = c(one = "C:/Data/Master/Data/ClimateAndObserved/lincoln.met")

library(ApsimOnR)

change_apsimx_param <- function(exe, file_to_run, param_values) {
  
  
  # Generate config file containing parameter changes ---------------------------
  config_file <- tempfile('apsimOnR', fileext = '.conf')
  parameter_names <- names(param_values)
  fileConn <- file(config_file)
  lines <- vector("character", length(param_values))
  for (i in 1:length(param_values))
    lines[i] <- paste(parameter_names[i], '=', as.character(param_values[i]))
  writeLines(lines, fileConn)
  close(fileConn)
  
  # Apply parameter changes to the model -----------------------------------------
  cmd <- paste(exe, file_to_run, '/Edit', config_file)
  #edit_file_stdout <- shell(cmd, translate = FALSE, intern = TRUE, mustWork = TRUE)
  edit_file_stdout <- system2(cmd, wait = TRUE)
  
  #print(edit_file_stdout)
  
  # returning the changes status
  return(is.null(attr(edit_file_stdout,"status")))
  
}
change_apsimx_param(exe = "c:/Data/20200311ApsimX/Bin/Models.exe",
                    file_to_run = "c:/Data/Master/Data/ApsimxFiles/20191022_LucerneSWCwith_obs.apsimx", 
                    param_values = paras)

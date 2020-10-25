loadd(info)
best_files = lapply(seq(1, nrow(info)), function(x){
  orig = here::here("03processed-data/apsimxFiles/")
  basename = paste0("ModifiedSKL_", 
                    info[x, ][["SKL"]],
                    info[x, ][["Experiment"]], 
                    info[x, ][["SowingDate"]], ".db")
  file.path(orig, basename)
})
bestfiles = best_files %>% unlist()
file.copy(bestfiles, to = "./03processed-data/apsimxLucerne/")
file.copy(gsub("\\.db$", "\\.apsimx",bestfiles), to = "./03processed-data/apsimxLucerne/")


best_files = lapply(seq(1, nrow(info)), function(x){
  orig = here::here("03processed-data/apsimxFiles/")
  basename = paste0("ModifiedSKL_", 
                    info[x, ][["SKL"]],
                    info[x, ][["Experiment"]], 
                    info[x, ][["SowingDate"]], ".db")
  file = file.path(orig, basename)
  dt = read_dbtab(file, "SummaryNumbers")
  dt[, ':='(Experiment = info[x, ][["Experiment"]],
            SowingDate = info[x, ][["SowingDate"]],
            SKL = info[x, ][["SKL"]])]
  
  dt = dt[SimulationID == info[x, ][["SimulationID"]]]
})
kls = process_list(best_files)
kls

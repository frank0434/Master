mets <- list.files("01raw-data/ClimateAndObserved/", pattern = ".met")


path <- unlist(lapply(mets, function(x){
  a = paste0("C:\\Data\\Master\\01raw-data\\ClimateAndObserved\\", x)
  names(a) <- ".Simulations.New Zealand.Iversen_12.Simulation3.Weather.FileName "
  a
}))

names(path[1])

library(ApsimOnR)

change_apsimx_param("../20200311ApsimX/Bin/Models.exe", 
                    file_to_run = "01raw-data/ApsimxFiles/test.apsimx",
                    param_values = path[1])

# test multiple 

clock.address =".Simulations.New Zealand.Iversen_12.Simulation3.clock.Start"
st = "1900-02-03T00:00:00"
value = c(path[1], st)
names(value) = c(names(path[1]), clock.address)
value
change_apsimx_param("../20200311ApsimX/Bin/Models.exe", 
                    file_to_run = "01raw-data/ApsimxFiles/test.apsimx",
                    param_values = value)
.Simulations.NZ.Iversen_12.Simulation3.Weather.FileName = C:\Data\Master\01raw-data\ClimateAndObserved\lincoln.met
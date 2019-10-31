library(jsonlite)
apsimx <- read_json("./Data/Lucerne/20191022_LucerneSWCwith_obs.apsimx", pretty = TRUE)
glimpse(apsimx$Children[[2]]$Children[[1]]$Children[[6]]$Children[[2]])

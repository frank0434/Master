source("R/packages.R")
library(targets)

template <- tar_read(template)
dir_metfile <- dir_met
cover <- tar_read(LAI_input)[2]
observed <- tar_read(observed)[2]
 dir_simulations
dir_config <- dir_config
apsimx <- path_apsimx
apsimx_Basefile <- apsimx_Basefile
DUL_LL_range <- tar_read(DUL_LL_range_arbitrary)
bulkDensity <- tar_read(BDs)
SowingDates <- tar_read(sowingDates)
SW_initial <- tar_read(SW_initials)

library(targets)

# Source functions
source("R/functions.R")
source("R/packages.R")
# Set constants 
path_richard <- "C:/Users/cflfcl/Dropbox/Data/APSIM_Sim.xlsx"


# Set target-specific options such as packages.
tar_option_set(packages = c("data.table", "magrittr", "readxl", 
                            "ggplot2", "here", "autoapsimx"))


# Define targets
targets <- list(
  tar_target(id_vars, c("Experiment", "SowingDate", "Clock.Today")),
  tar_target(value_vars, grep("SW\\(\\d.+", colnames(data_SW), value = TRUE)),
  tar_target(data_SW, read_Sims(path = path_richard)),
  tar_target(DUL_LL_range, doDUL_LL_range(SW = data_SW, id.vars = id_vars,
                                          value.vars = value_vars))
)

# End with a call to tar_pipeline() to wrangle the targets together.
# This target script must return a pipeline object.
tar_pipeline(targets)


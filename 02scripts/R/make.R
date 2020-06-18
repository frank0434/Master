
#configurations

kRpath <- here::here("02scripts/R")
path_sql <- here::here("03processed-data/Richard.sqlite3")
path_sims <- here::here("03processed-data/apsimxFiles/")
path_EDAfigures <- here::here("05figures/klEDA/")
#plan 
source(file.path(kRpath, "functions.R"))
source(file.path(kRpath, "packages.R"))
source(file.path(kRpath, "plan.R"))
source(file.path(kRpath, "plan_SW.R"))

# Constant

id_vars <- c("Experiment", "SowingDate", "Clock.Today")
Sites <- c("AshleyDene", "Iversen12")

stats_key <- c("Experiment", "SowingDate", "SimulationID", "KLR", "RFV", "SKL")
stats_key_SW <- c("Experiment", "SowingDate", "SimulationID", "KLR", "RFV", "SKL", "Depth")

stats_key_extra <- c(stats_key, "NSE", "R2", "RMSE")
stats_key_SW_extra <- c(stats_key_SW, "NSE", "R2", "RMSE")
drake::make(plan, lock_envir = F, memory_strategy = "autoclean", 
            garbage_collection = TRUE)
drake::make(plan_SW, lock_envir = F, memory_strategy = "autoclean", 
            garbage_collection = TRUE)

library(visNetwork) 
vis_drake_graph(
  plan, targets_only = TRUE,
  font_size = 25,
  # file = "05figures/dependency.png",
  navigationButtons = FALSE
  # parallelism = "clustermq",
  # jobs = 16
)
drake_ggraph(plan)

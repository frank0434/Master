

# Run plan
library(drake)
drake::r_make()
r_outdated(r_args = list(show = FALSE))
#> character(0)

r_vis_drake_graph(targets_only = TRUE, r_args = list(show = FALSE))
# Run simulations
cmd = paste(path_apsimx, paste0(path_sims, "/*.apsimx"), 
            "/MultiProcess",
            "/NumberOfProcessors:8")
run_apsimx = system(cmd)
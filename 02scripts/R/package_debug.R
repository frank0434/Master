

library(drake)



# stats fail --------------------------------------------------------------

# x fail stats
# Error: target stats failed.
# diagnose(stats)error$message:
#   Invalid argument type: 'sim' & 'obs' have to be of class: c('integer', 'numeric', 'ts', 'zoo')
# diagnose(stats)error$calls:
#   1. \-autoapsimx::sims_stats(pred_obs = pred_swc)
# 2.   +-...[]
# 3.   \-data.table:::`[.data.table`(...)
# 4.     \-base::eval(jsub, SDenv, parent.frame())
# 5.       \-base::eval(jsub, SDenv, parent.frame())
# 6.         \-base::lapply(...)
# 7.           \-autoapsimx:::FUN(X[[i]], ...)
# 8.             +-hydroGOF::gof(x$PSWC, x$SWC)
# 9.             \-hydroGOF::gof.default(x$PSWC, x$SWC)
# 10.               +-hydroGOF::me(sim, obs, na.rm = na.rm)
# 11.               \-hydroGOF::me.default(sim, obs, na.rm = na.rm)
# 12.                 \-base::stop("Invalid argument type: 'sim' & 'obs' have to be of class: c('integer', 'numeric', 'ts', 'zoo')")


loadd()
ls()
pred_swc
# The manipulate fun didn't join the two DT correctly. 
# Because column SWC has been filtered out 
obs_sd
pred_swc
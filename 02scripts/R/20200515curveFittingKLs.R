# the model was failed somehow FOR THIS particular subset 
# this is a debug process 
# Depends on .2_Data_EAD.Rmd


PROBLEM1 <- nested[Experiment =="Iversen12" & SowingDate == "SD10" ]
PROBLEM1[, unlist(data, recursive = FALSE), by = .(Experiment, variable)]%>% 
  ggplot(aes(Clock.Today, value)) + 
  geom_point() +
  facet_grid(variable ~ .)
test <- PROBLEM1[, unlist(data, recursive = FALSE), by = .(Experiment, variable)][variable=="SW(1)"]

ll.0 =  min(test$value)/2
# Use a simple liner model to get the starting points for the decay rate _kl_
# The liner model has to be log transferred first 
model.0 = lm(log(value - ll.0) ~ t, data = test)  
pawc.0 = exp(coef(model.0)[1]) # The starting point for interception
kl.0 = coef(model.0)[2] # kl starting point
#  Starting parameters
start = list(PAWC = pawc.0, kl = kl.0, LL = ll.0)
tryCatch({
  model = nls(value ~ PAWC * exp(kl * t) + LL , data = test, start = start)
},
error = function(cond){
  message("nls can't describe the data")
  message(cond)
  return(NA)
})
broom::tidy(model)

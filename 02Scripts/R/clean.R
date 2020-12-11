# Depends on the plan.R
# drake::clean(list = cached_unplanned(plan), garbage_collection = TRUE)
#clean with care
drake::clean(destroy = TRUE)

drake::which_clean()
drake::clean(starts_with("plot"), garbage_collection = TRUE)

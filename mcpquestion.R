library(ggplot2)
library(mcp)
library(data.table)
ADSD2 = readRDS('SoilMoistureSD2.rds')
model = list(
  relativeSW ~ 1 ,  # plateau (int_1)
  ~ 0 + DAS,       # joined slope (time_2) at cp_1, could be a exp decay function.
  ~ 1 + DAS ,            # joined slope (int_3, time_3) at cp_2 - plateau
  ~ 0 + DAS        # joined slope at cp_3 - infiltration front
)
DT = ADSD2[Depth ==1 ]
fit = mcp(model, data = DT, cores = 3)
# Extract the cp one 
cp_1_est = as.data.table(summary(fit))
plot(fit) + geom_vline(xintercept = cp_1_est$mean[1])

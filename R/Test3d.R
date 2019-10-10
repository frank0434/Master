library(rgl)
data(volcano)
z <- 2 * volcano # Exaggerate the relief
x <- 10 * (1:nrow(z)) # 10 meter spacing (S to N)
y <- 10 * (1:ncol(z)) # 10 meter spacing (E to W)
zlim <- range(z)
zlen <- zlim[2] - zlim[1] + 1
colorlut <- terrain.colors(zlen,alpha=0) # height color lookup table
col <- colorlut[ z-zlim[1]+1 ] # assign colors to heights for each point
open3d()
rgl.surface(x, y, z, color=col, alpha=0.75, back="lines")


source("R/chart3d.R")
library(xts)
TR <- getUSTreasuries("2018")
chartSeries3d0(TR)

sd1 <- soilwater[Sowing.Date == "SD1" & Site == "AshleyDene"][,-c(1:2,4:5,7:9, 33)]
sd1 <- sd1[, Rep := as.integer(Rep)] %>% 
  dcast(., Date ~ Rep)
xts1 <- as.xts(sd1,order.by = "Date")
chartSeries3d0(xts1)

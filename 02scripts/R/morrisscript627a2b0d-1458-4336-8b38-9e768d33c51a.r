.libPaths(c('C:/Users/cflfcl/AppData/Roaming/ApsimInitiative/ApsimX/rpackages', .libPaths()))
library('sensitivity', lib.loc = 'C:/Users/cflfcl/AppData/Roaming/ApsimInitiative/ApsimX/rpackages')
params <- c("ResidueWt","CN2","Cona","U","ResidueCNR","SWCon","DUL")
apsimMorris<-morris(model=NULL
 ,params #string vector of parameter names
 ,25 #no of paths within the total parameter space
 ,design=list(type="oat",levels=21,grid.jump=10)
 ,binf=c(0,70,3,1,40,0.1,0.2611) #min for each parameter
 ,bsup=c(5000,85,9,9,120,0.5,0.5) #max for each parameter
 ,scale=T
 )
apsimMorris$X <- read.csv("C:/Users/cflfcl/AppData/Local/Temp/parameters627a2b0d-1458-4336-8b38-9e768d33c51a.csv")
values = read.csv("C:/Users/cflfcl/AppData/Local/Temp/apsimvariable627a2b0d-1458-4336-8b38-9e768d33c51a.csv")
allEE <- data.frame()
allStats <- data.frame()
for (columnName in colnames(values))
{
 apsimMorris$y <- values[[columnName]]
 tell(apsimMorris)
 ee <- data.frame(apsimMorris$ee)
 ee$variable <- columnName
 ee$path <- c(1:25)
 allEE <- rbind(allEE, ee)
 mu <- apply(apsimMorris$ee, 2, mean)
 mustar <- apply(apsimMorris$ee, 2, function(x) mean(abs(x)))
 sigma <- apply(apsimMorris$ee, 2, sd)
 stats <- data.frame(mu, mustar, sigma)
 stats$param <- params
 stats$variable <- columnName
 allStats <- rbind(allStats, stats)
}
write.csv(allEE,"C:/Users/cflfcl/AppData/Local/Temp/ee627a2b0d-1458-4336-8b38-9e768d33c51a.csv", row.names=FALSE)
write.csv(allStats, "C:/Users/cflfcl/AppData/Local/Temp/stats627a2b0d-1458-4336-8b38-9e768d33c51a.csv", row.names=FALSE)

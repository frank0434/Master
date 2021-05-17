
rm(list=ls())
stem = "C:/Users/clecarpenti/Documents/sauvegarde_rapeseed_partielle/Modelisation/Troisieme-run-FSPM2020/"

path = paste0(stem,"2-SensitivityAnalysis/")
out_path = paste0(stem, "simulation_output/")


library(multisensi)
library(wesanderson)

wes_palette("Royal1")


# LOADING SIMULATION OUTPUTS

Set = "ThdAS-Fst-One-005"
AS = read.table(paste0(out_path, "Out-", Set, ".csv"), sep=";", header=TRUE, dec=".")
AS$EL = AS$ELONG
AS$IBD = AS$DIR
AS$DelBEl = AS$DURDEVPRIM



summary(AS)

{
  ## Calculate main sensitivity indices and total sensitivity indices
  # DEFINE OUTPUT AND INPUT PARAMETERS
  
  Ys = c("BIOMASS","ROOTPROPORTION", "EXPLOREDSOILVOLUME","COLONIZATIONEFFICIENCY")
  Xs = c("DelBEl","DMIN","DMAX","EL","IBD","DLDM","VARD","RTD")
  
  as_01 = dynsi(formula = 2, model = as.data.frame(AS[,Ys]), factors = AS[,Xs])
  
  
  ## Calculate Residuals

  Res_01 = (1-colSums(as_01$SI))[1:length(Ys)]
  
}

#################### FIGURE 3 ###
#################################

png(paste0(path,"ArchiSimple-Sensitivity-Analysis-Thd-n7.png"), width = 8, height = 7, unit = "in", res=600)
{
  
  par(mfrow=c(2,2), mar=c(4,4,4,0.5))
  ymax = 0.7#max(c(as_svn_15$mSI[,Ys], as_svn_15$iSI[,Ys]))
  ymin = 0
  
  
  ### all plants
  
  # vector_color = rep(c("forestgreen","yellowgreen"), times = length(Xs))
  vector_color = c(wes_palette("Royal1")[2],wes_palette("Royal1")[1] )
  
  ## Biomass
  barplot(t(as.matrix(data.frame(MSI = as_01$mSI[,"BIOMASS"], ISI = as_01$iSI[,"BIOMASS"]))), beside=TRUE, las=3, ylim=c(ymin,ymax), main = "Root System Biomass", col = vector_color,ylab = "Indice Value")
  legend("topright", legend = c("MSI","ISI"), fill = vector_color, bty="n")

  ## Biomass
  barplot(t(as.matrix(data.frame(MSI = as_01$mSI[,"ROOTPROPORTION"], ISI = as_01$iSI[,"ROOTPROPORTION"]))), beside=TRUE, las=3, ylim=c(ymin,ymax), main = "Proportion of thin roots", col = vector_color,ylab = "Indice Value")
  legend("topright", legend = c("MSI","ISI"), fill = vector_color, bty="n")
  
  ##Exploration of space
  barplot(t(as.matrix(data.frame(MSI = as_01$mSI[,"EXPLOREDSOILVOLUME"], ISI = as_01$iSI[,"EXPLOREDSOILVOLUME"]))), beside=TRUE, las=3, ylim=c(ymin,ymax), main = "Soil Exploration (pyramid)", col = vector_color,ylab = "Indice Value")
  legend("topright", legend = c("MSI","ISI"), fill = vector_color, bty="n")
  
  ##Colonization efficiency
  barplot(t(as.matrix(data.frame(MSI = as_01$mSI[,"COLONIZATIONEFFICIENCY"], ISI = as_01$iSI[,"COLONIZATIONEFFICIENCY"]))), beside=TRUE, las=3, ylim=c(ymin,ymax), main = "Colonization efficiency", col = vector_color,ylab = "Indice Value")
  legend("topright", legend = c("MSI","ISI"), fill = vector_color, bty="n")
  
}
dev.off()








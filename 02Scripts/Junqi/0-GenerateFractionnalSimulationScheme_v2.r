
rm(list=ls())

stem = "C:/Users/clecarpenti/Documents/sauvegarde_rapeseed_partielle/Modelisation/Troisieme-run-FSPM2020/"

design_path = paste0(stem,"simulation_scheme/")

setwd(paste0(path))

bd_ind = read.table("C:/Users/clecarpenti/Documents/sauvegarde_rapeseed_partielle/Experimentations/Avril-2018/Analyses-Statistiques/data/la-bd-finale/csv/final-bd-ind.csv", header=TRUE, dec = ",", sep=";")

ExP = read.table("C:/Users/clecarpenti/Documents/sauvegarde_rapeseed_partielle/Modelisation/MyExperimentalParameters.csv", header=TRUE, dec = ".", sep=";")

##############################################################################################
#########   DEFINING VARIATION RANGES OF INPUT PARAMETERS  ###################################
##############################################################################################

my_duration = 40

SetInputValues = function(n, x_min, x_max, gamma)
{
  delta = x_max - x_min
  x_mean = (x_min + x_max)/2
  y_min = x_mean - (delta*gamma)/2
  y_max = x_mean + (delta*gamma)/2
  
  pas = (delta*gamma)/(n-1)
  my_gamme = NULL
  for (i in 1:n)
  {
    my_gamme = c(my_gamme, y_min + ((i-1) * pas))
  }
  return(my_gamme)
}



######################################################################################################
#########    SETTING UP THE FRACTIONNAL SCHEME   #####################################################
######################################################################################################
n_values = 7

# SELECTING APPROPRIATE DATAFRAME

ref_genotype = "all"
ref_N = "all"
ref_T = "Opaque"


  if(ref_genotype == "all")
  {
    if(ref_N == "all")
    {
      if(ref_T == "all")
      {
        ref_dF = ExP
      }else{
        ref_dF = subset(ExP, T == ref_T)  
      }
    }else{
      ref_dF = subset(ExP, N == ref_N & T == ref_T)  
    }
  }else{
  ref_dF = subset(ExP, N == ref_N & Geno == ref_genotype & T == ref_T)
  }


my_gamma = 1

{
# 7 architecture parameters
factors_DMIN = SetInputValues(gamma = my_gamma, n = n_values, x_min = as.numeric(quantile(ref_dF$Dmin, probs = 0.05)), x_max = as.numeric(quantile(ref_dF$Dmin, probs = 0.95)))
factors_DMAX = SetInputValues(gamma = my_gamma, n = n_values, x_min = as.numeric(quantile(ref_dF$Dmax, probs = 0.05)), x_max = as.numeric(quantile(ref_dF$Dmax, probs = 0.95)))
factors_DIR = SetInputValues(gamma = my_gamma, n = n_values, x_min = as.numeric(quantile(ref_dF$IBD, probs = 0.05)), x_max = as.numeric(quantile(ref_dF$IBD, probs = 0.95)))
factors_DLDM = SetInputValues(gamma = my_gamma, n = n_values, x_min = as.numeric(quantile(ref_dF$DlDm, probs = 0.05)), x_max = as.numeric(quantile(ref_dF$DlDm, probs = 0.95)))
factors_VARD = SetInputValues(gamma = my_gamma, n = n_values, x_min = as.numeric(quantile(ref_dF$VarD, probs = 0.05)), x_max = as.numeric(quantile(ref_dF$VarD, probs = 0.95)))
factors_RTD = SetInputValues(gamma = my_gamma, n = n_values, x_min = as.numeric(quantile(ref_dF$RTD, probs = 0.05)), x_max = as.numeric(quantile(ref_dF$RTD, probs = 0.95)))
factors_ELONG = SetInputValues(gamma = my_gamma, n = n_values, x_min = as.numeric(quantile(ref_dF$Elong, probs = 0.05)), x_max = as.numeric(quantile(ref_dF$Elong, probs = 0.95)))

# 5 constants
factors_DURDEVPRIM = SetInputValues(gamma = 1, n = n_values, x_min = 3, x_max = 9)
}

#Charging the necessarty packages
library(planor)

{
#Defining the factors
#They must have the same names they have in the model
all_params = c("DURDEVPRIM","DMIN","DMAX","ELONG","DIR","DLDM","VARD","RTD")

facteurs = planor.factors(factors = all_params, nlevels = n_values)

#Definig the resolution
modele = planor.model (factors = facteurs, resolution = 5)

#Defining the number of simulation needed
keys = planor.designkey(factors = facteurs, model = modele, nunits = n_values^5 , verbose = T)


#Generating the plan matrix
plan = planor.design(keys)
simulation_scheme = plan@design

print(paste("n_values", n_values, dim(simulation_scheme)[1]))

head(simulation_scheme)
}
################################################################################################################
###############  AFFECTING VALUES TO OUR SCHEME    #############################################################
################################################################################################################


{
# 7 architecture parameters
levels(simulation_scheme$DMIN) = factors_DMIN
levels(simulation_scheme$DMAX) = factors_DMAX
levels(simulation_scheme$ELONG) = factors_ELONG
levels(simulation_scheme$DIR) = factors_DIR
levels(simulation_scheme$DLDM) = factors_DLDM
levels(simulation_scheme$VARD) = factors_VARD
levels(simulation_scheme$RTD) = factors_RTD

# 4 constants
levels(simulation_scheme$DURDEVPRIM) = factors_DURDEVPRIM
}

################################################################################################################
###############  ADDING FIXED VALUES ###########################################################################
################################################################################################################

# MANNUALLY SET

# 5 constants

simulation_scheme$DURATION = my_duration
simulation_scheme$COEFFDURVIE = 10000
simulation_scheme$COEFFDURCROISS = 200
simulation_scheme$COEFFDURVIE = 10000
simulation_scheme$COEFFCROISSRAD = 0.3
simulation_scheme$VITEMISSEM = 0.2

## Exporting Simulation Scheme

summary(simulation_scheme)

write.table(simulation_scheme, file = paste0(design_path,"Des-","ThdAS-Fst-One-005.csv"), row.names = F, sep=";")

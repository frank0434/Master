## APSIM soybean phenology function - version April 19, 2013
## Archontoulis SV, Miguez FE, Moore KJ, 2014 - Envrin Modelling & Software
## doi: http://dx.doi.org/10.1016/j.envsoft.2014.04.009 
## Table 1 (in the paper) provides a list with all the parameter values used,
## their definition and the range of values. 
## Updates by FEM May 27th 2014
## Updates by SVA May 28th 2014
##
## Authors: Sotirios Archontoulis and Fernando Miguez

#############################################################################################################
#############################################################################################################
## This function calculates photoperiod. The first argument to the
## function is a file with observed data. This function assumes that
## the object with observed data has an element called 'latitude'. The
## second argument is the 'met' file which should contain a column
## with the day of the year called 'day'. The sun angle is a user 
## input parameter and refers to twilight. We used zero
## in our imulations  (Table 1), but it could be -6 such as in APSIM.
## The function returns a data frame with day and photoperiod
## source: APSIM version 7.4

photoperiod <- function(obs, met, sun_angle=0){
  
  lat <-  obs$latitude[1]         # read latitude from the Measured file
  day <-  met$day                 # read day from the Met file 
  
  aeqnox <- 79.25              
  pi     <- 3.14159265359
  dg2rdn <- (2.0*pi) /360.0    
  decsol <- 23.45116 * dg2rdn  
  dy2rdn <- (2.0*pi) /365.25   
  rdn2hr <- 24.0/(2.0*pi)      
  
  sun_alt <- sun_angle * dg2rdn
  dec     <- decsol*sin (dy2rdn* (day - aeqnox))
  latrn   <- lat*dg2rdn;
  slsd    <- sin(latrn)*sin(dec)
  clcd    <- cos(latrn)*cos(dec)
  altmn   <- asin(pmin(pmax(slsd - clcd, -1.0), 1.0))
  altmx   <- asin(pmin(pmax(slsd + clcd, -1.0), 1.0))
  alt     <- pmin(pmax(sun_alt, altmn), altmx)
  
  coshra1 <- (sin (alt) - slsd) /clcd
  coshra  <- pmin(pmax(coshra1, -1.0), 1.0);
  hrangl  <- acos (coshra)
  PP      <- hrangl*rdn2hr*2.0          
  res <- data.frame(day = day, photoperiod=PP)
  return(res)
}

#############################################################################################################
#############################################################################################################
## This generic function calculates gdd target from daily PP.
## We call this function later on in this cript to estimate
## gdd targets for each photoperiod affected phase.
## PP = daily photoperiod, pcrit1 = critical photoperiod
## psen1 = photoperiodic sensitivity, 
## par = physiological days (see Table 1 for values) 
## opt = maximum gdd for APSIM soybean 

pp2gdd <- function(pp, pcrit1, psen1, par, opt=(30-10)){

  ans <- numeric(length(pp))

  pcrit_max <- (pcrit1*psen1+1)/psen1           # e.g. pcrit1=13.59, psen1=0.249, so pcrit_max=17.6 correct

  p1 <- pcrit1                                  # 13.59 hours  
  p2 <- 0.75*pcrit1 + 0.25*pcrit_max            # 14.59 hours 
  p3 <- 0.50*pcrit1 + 0.50*pcrit_max            # 15.59 hours 
  p4 <- 0.25*pcrit1 + 0.75*pcrit_max            # 16.59 hours 

  d1 <- par*opt/(1-psen1*(p1 - pcrit1))         
  d2 <- par*opt/(1-psen1*(p2 - pcrit1))         
  d3 <- par*opt/(1-psen1*(p3 - pcrit1))         
  d4 <- par*opt/(1-psen1*(p4 - pcrit1))         

  for(i in 1:length(pp)){

    if(is.na(pp[i])) cat("pp[i]:",pp[i],"\n")
    if(is.na(p1)) cat("p1:",p1,"\n")
    
    if(pp[i] <= p1){
      ans[i] <- d1
    }
    
    if(pp[i] > p1 && pp[i] < p2){             # e.g.  
      int <- d1                               # 5 d
      slp <- (d2 - d1)/(p2-p1)                # (6.6-5)/(14.59-13.59) = 1.6
      ans[i] <- int + slp * (pp[i] - p1)      # 5 + 1.6 * (PP - 13.59)
    }

    if(pp[i] > p2 && pp[i] < p3){              
      int <- d2                              
      slp <- (d3 - d2)/(p3-p2)               
      ans[i] <- int + slp * (pp[i] - p2)     
    }

    if(pp[i] > p3 && pp[i] <= p4){           
      int <- d3                             
      slp <- (d4 - d3)/(p4-p3)              
      ans[i] <- int + slp * (pp[i] - p3)    
    }

    if(pp[i] > p4){
      ans[i] <- d4                          
    }
    
  }

  return(ans)

}


########################################################################################################
########################################################################################################
## Functions to convert temperature to gdd following APSIM's XY interpolation method. 
## There are three options available in this script. Users can modify or add new functions. 
## We used the temp2gdd function in the paper (APSIM-soybean version 7.5).
## We provide two more options as examples (temp3gdd and temp4dd function)
## See supplementary materials, figure S1  for the shape of each function

## function 1 or method 1 (temp2gdd)
temp2gdd <- function(temp, cardinal.temps = c(10,30,40), gdd.coord=c(0,20,0)){
  
  gdd <- numeric(length(temp))
  
  for(i in 1:length(temp)){
    if(temp[i] <= cardinal.temps[2]){
      slp <- c(gdd.coord[2]-gdd.coord[1])/c(cardinal.temps[2]-cardinal.temps[1])    # slope = (20-0)/(30-10)=1
      int <- gdd.coord[1]                                                           # int   = 0
      gdd[i] <- int + slp * (temp[i] - cardinal.temps[1])    
    }else{
      slp <- c(gdd.coord[3]-gdd.coord[2])/c(cardinal.temps[3]-cardinal.temps[2])    # slope = (0-20)/(40-30)=-2
      int <- gdd.coord[2]                                                           # int   = 20
      gdd[i] <- int + slp * (temp[i] - cardinal.temps[2])
    }
  }
  
  gdd <- pmax(gdd,0)
  return(gdd=gdd)
}


## function 2 or method 2 (temp3gdd)
temp3gdd <- function(temp, cardinal.temps = c(0,15,30,40), gdd.coord=c(0,5,20,0)){
  
  gdd <- numeric(length(temp))
  
  for(i in 1:length(temp)){
    if(temp[i] <= cardinal.temps[2]){                                                 # temp < 15
      slp <- c(gdd.coord[2]-gdd.coord[1])/c(cardinal.temps[2]-cardinal.temps[1])      # slope = (5-0)/(15-0)=0.333
      int <- gdd.coord[1]                                                             # int = gdd.coord[1] = 0
      gdd[i] <- int + slp * (temp[i] - cardinal.temps[1])                             # if temp = 15, gdd=5
    }
    if(temp[i] > cardinal.temps[2] && temp[i] <= cardinal.temps[3]){                  # temp < 30
      slp <- c(gdd.coord[3]-gdd.coord[2])/c(cardinal.temps[3]-cardinal.temps[2])      # slope = (20-5)/(30-15)=1
      int <- gdd.coord[2]                                                             # int = gdd.coord[2] = 5
      gdd[i] <- int + slp * (temp[i] - cardinal.temps[2])                             # if temp = 30, gdd=20
    }
    if(temp[i] > cardinal.temps[3] && temp[i] <= cardinal.temps[4]){                  # temp < 40
      slp <- c(gdd.coord[4]-gdd.coord[3])/c(cardinal.temps[4]-cardinal.temps[3])      # slope = (0-20)/(40-30)=-2
      int <-  gdd.coord[3]                                                            # int = gd.coord[3]=20
      gdd[i] <- int + slp * (temp[i] - cardinal.temps[3])                             # if temp = 40, gdd=0
      #}else{
      # gdd[i] <- 0
    }
  }
  gdd <- pmax(gdd,0)
  return(gdd=gdd)
}


## function 3 or method 3 (temp4gdd)
temp4gdd <- function(temp, cardinal.temps = c(7,28,35,45), gdd.coord=c(0,21,21,0)){
  
  gdd <- numeric(length(temp))
  
  for(i in 1:length(temp)){
    if(temp[i] <= cardinal.temps[2]){                                                 # temp < 28
      slp <- c(gdd.coord[2]-gdd.coord[1])/c(cardinal.temps[2]-cardinal.temps[1])      # slope = (21-0)/(28-7)=1
      int <- gdd.coord[1]                                                             # int = gdd.coord[1] = 0
      gdd[i] <- int + slp * (temp[i] - cardinal.temps[1])                             # if temp = 28, gdd=21
    }
    if(temp[i] > cardinal.temps[2] && temp[i] <= cardinal.temps[3]){                  # temp < 35
      slp <- c(gdd.coord[3]-gdd.coord[2])/c(cardinal.temps[3]-cardinal.temps[2])      # slope = (21-21)/(35-28)=0
      int <- gdd.coord[2]                                                             # int = gdd.coord[2] = 21
      gdd[i] <- int + slp * (temp[i] - cardinal.temps[2])                             # if temp = 35, gdd=21
    }
    if(temp[i] > cardinal.temps[3] && temp[i] <= cardinal.temps[4]){                  # temp < 45
      slp <- c(gdd.coord[4]-gdd.coord[3])/c(cardinal.temps[4]-cardinal.temps[3])      # slope = (0-21)/(45-35)=-2.1
      int <-  gdd.coord[3]                                                            # int = gd.coord[3]=21
      gdd[i] <- int + slp * (temp[i] - cardinal.temps[3])                             # if temp = 45, gdd=0
     }
  }
  gdd <- pmax(gdd,0)
  return(gdd=gdd)
}


########################################################################################################
########################################################################################################
## This function calculates daily gdd using the 3-hour interval approach from APSIM
## Min and max daily temperature, Tb, To, and interpolation method are the inputs (see above for options).
## We used the "temp2gdd" interpolation method and APSIM's default Tb and To values (Table 1).   

gdd <- function(maxt, mint, Tb=10, To=30, method = c("temp2gdd", "temp3gdd", "temp4gdd")){

  h2c <- function(hr){
    ans <- 0.92105 + 0.114 * hr - 0.0703 * hr^2 + 0.0053*hr^3   # apsim equation  
    ans
  } 
    
  method <- match.arg(method)
  
  if(method == "temp2gdd"){
    if(mint < Tb || maxt > To){
      temp1 <- mint + h2c(1)*(maxt - mint)
      temp2 <- mint + h2c(2)*(maxt - mint)
      temp3 <- mint + h2c(3)*(maxt - mint)
      temp4 <- mint + h2c(4)*(maxt - mint)
      temp5 <- mint + h2c(5)*(maxt - mint)
      temp6 <- mint + h2c(6)*(maxt - mint)
      temp7 <- mint + h2c(7)*(maxt - mint)
      temp8 <- mint + h2c(8)*(maxt - mint)
      
      gdd <- mean(temp2gdd(c(temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8)))  
    }else{
      gdd <- temp2gdd((maxt + mint)*0.5)                                                 
    } 
  }else{
    if(mint < Tb || maxt > To){
      temp1 <- mint + h2c(1)*(maxt - mint)
      temp2 <- mint + h2c(2)*(maxt - mint)
      temp3 <- mint + h2c(3)*(maxt - mint)
      temp4 <- mint + h2c(4)*(maxt - mint)
      temp5 <- mint + h2c(5)*(maxt - mint)
      temp6 <- mint + h2c(6)*(maxt - mint)
      temp7 <- mint + h2c(7)*(maxt - mint)
      temp8 <- mint + h2c(8)*(maxt - mint)
      
      gdd <- mean(temp3gdd(c(temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8)))   
    }else{
      gdd <- temp3gdd((maxt + mint)*0.5)                                                 
    }
  }

  return(gdd)
}

  
########################################################################################################
########################################################################################################
## The soybean phenology function
## Detailed description in given in the sections 2.2 and 2.3.3
## Some additional comments can be found below 
## obs refers to the observation file (see supplementary Tables S1 for the format)
## met refers to the meteorological file (see supplementary Tables S2 for the format)
## for pcrit1, psen1 and sun_angle see Table 1 for values
## parameters aa, bb, cc and ss are named a1, a2, a3, and [a4+a5], respectively in Table 1


## the phenology function
## note in the optimization script we have added a look-up table for soybean cultivars with starting values
## the user can modify the starting values in the optimization script and not in this script
phenology <- function(obs, met, pcrit1=14.1,  psen1=0.171, psen2=0.171, aa=5, bb=5, cc=5.6, ss=34, sun_angle=0, temp.method = "temp2gdd"){

  if(nrow(met) < 365) stop("met file incomplete")
    
  day1 <-  obs$Sow[1]                                                        # start day
  day2 <- max(c(365-day1, obs$PM[1] + 20))                                   # end day plus few days 
  dayn <- day1 + day2
  dayn <- 365
    
  maxt <- subset(met, day >= day1 & day <= dayn)$maxt
  mint <- subset(met, day >= day1 & day <= dayn)$mint
  PP   <- photoperiod(obs = obs, met=met, sun_angle=sun_angle)$photoperiod   # calculate PP from the photoperiod function
  
  maxt.n <- length(maxt)
  gdd <- numeric(maxt.n)                                                     # gdd for the entire season
  gddP <- numeric(7)                                                         # gdd for each phase (reset)
  phase <- numeric(maxt.n)
  old.gdd2 <- 0
  old.gdd3 <- 0
  old.gdd4 <- 0
  old.gdd5 <- 0
  old.gdd6 <- 0
  old.gdd7 <- 0
  
  target <- numeric(7) 
  days <- numeric(maxt.n)
  old.gdd <- 0
  
  ## Constant values and minimum gdd needed for a phase  
  Tb            <- 10                                                       # base temperature
  To            <- 30                                                       # optimum temperature
  Tc            <- 40                                                       # ceiling temperature
  Rmax          <- To - Tb                                                  # max rate of development per day
  dd           <- 0.333295775 * ss                                          # dd = a4 in Table 1, for 0.33 see sections 3.5 and 4.3 in the paper
  ee           <- ss - dd                                                   # ee = a5 in Table 1  
  VE_JUV_min    <- aa                                                       # phase duration, aa = a1 in Table 1
  JUV_FI_min    <- bb * Rmax                                                # phase duration, bb = a2 in Table 1
  FI_FL_min     <- cc * Rmax                                                # phase duration, cc = a3 in Table 1
  FL_SD_min     <- dd * Rmax                                                # phase duration
  SD_END_min    <- ee * Rmax                                                
  END_PM_min    <- 1
  
  k <- 0
  j <- day1
  
  
  ## Calculate thermal target from sowing to emergence based on observed data or APSIM simulation of seed emergence
  sowGDDmet   <- subset(met, day >= obs$Sow[1] & day <= (obs$Sow[1] + obs$VE[1]))
  SOW_VE_maxt <- sowGDDmet[,c("maxt")]
  SOW_VE_mint <- sowGDDmet[,c("mint")]
  
  gdd_SOW_VE <- numeric(length(SOW_VE_maxt))
  
  for(i in 1:length(SOW_VE_maxt)){
    gdd_SOW_VE[i] <- gdd(SOW_VE_maxt[i], SOW_VE_mint[i], Tb=Tb, To=To, method=temp.method)
  }

  SOW_VE <- sum(gdd_SOW_VE)
  
  ## Calculate dynamic thermal Targets as a function of photoperiod for different crop phases  
  VE_JUV <- VE_JUV_min * Rmax                                            # phase is not affected by PP
  JUV_FI <- pp2gdd(PP, pcrit1=pcrit1, psen1=psen1, par=bb)               # phase is affected by PP
  FI_FL  <- pp2gdd(PP, pcrit1=pcrit1, psen1=psen1, par=cc)
  FL_SD  <- pp2gdd(PP, pcrit1=pcrit1, psen1=psen2, par=dd)
  SD_END <- pp2gdd(PP, pcrit1=pcrit1, psen1=psen2, par=ee)
  END_PM <- END_PM_min * Rmax                                             
  
  photothermal <- data.frame(VE_JUV=VE_JUV,JUV_FI=JUV_FI, FI_FL=FI_FL, FL_SD=FL_SD, SD_END=SD_END, END_PM=END_PM)

  # starting value for each phase - this avoids problems during optimization
  day_SOW_VE  <- 0
  day_SOW_JUV <- 0
  day_SOW_FI  <- 0
  day_SOW_FL  <- 0
  day_SOW_SD  <- 0
  day_SOW_END <- 0
  day_SOW_PM  <- 0
  
  i1 <- 0
  i2 <- 0
  i3 <- 0
  i4 <- 0
  i5 <- 0
  i6 <- 0
  i7 <- 0
  
  for(i in 1:day2){
    
    ## Calculate and accumulate gdd starting from planting day for each treatment in the Measured file 
    curr.gdd   <- gdd(maxt=maxt[i], mint=mint[i], Tb=Tb, To=To, method=temp.method)        # today's gdd
    tom.gdd   <- gdd(maxt=maxt[i+1], mint=mint[i+1], Tb=Tb, To=To, method=temp.method)     # Tomorrow's gdd
    gdd[i]     <- old.gdd + curr.gdd      
    old.gdd    <- old.gdd + curr.gdd
    
    ## Estimate crop phases and count DAS needed to complete each phase
    ## if the accumulated gdd from sowing < SOW_VE target, then output phase "SOW_VE" 
    ## When the accumulated gdd from sowing equals SOW_VE target (e.g. 50 Cd) then 
    ## track/sum and output DAS needed to complete this pahase (e.g. 5 DAS)
    ## then optimize parameters to minimize the difference between estimated and observed DAS
    ## then reset gdd accumulation to start accumulating new gdd towards the next stage
    
    ## gdd for the first phase, ends at emergence
    if(gdd[i] >= SOW_VE && i1 == 0){
      gddP[1] <- gdd[i]
      target[1] <- SOW_VE
      day_SOW_VE <- i - 1
      old.gdd1 <- gdd[i]
      i1 <- 1
    }
    ## This is for the second phase, ends at juvenile 
    if(gdd[i] >= (SOW_VE+VE_JUV) && i2 == 0) {
      gddP[2] <- gdd[i]
      target[2] <- VE_JUV
      old.gdd2 <- gdd[i] - SOW_VE
      day_SOW_JUV <- i
      i2 <- 1
    }
    ## This is for the third phase, ends at FI
    if(gdd[i] >= (SOW_VE+VE_JUV+JUV_FI[j]) && i3 == 0){
      gddP[3] <- gdd[i]
      target[3] <- JUV_FI[j]
      old.gdd3 <- gdd[i] - (SOW_VE+VE_JUV)
      day_SOW_FI <- i
      i3 <- 1
    }
    ## This is for the fourth phase, ends at FL 
    if(gdd[i] >= (SOW_VE+VE_JUV+JUV_FI[day_SOW_FI + day1]+FI_FL[j]) && i4 == 0){
      gddP[4] <- gdd[i]
      target[4] <- FI_FL[j]
      old.gdd4 <- gdd[i] - (SOW_VE+VE_JUV+JUV_FI[day_SOW_FI + day1])
      day_SOW_FL <- i
      i4 <- 1
    }
    ## This is for the fifth phase, ends at SD
    if(gdd[i] >= (SOW_VE+VE_JUV+JUV_FI[day_SOW_FI + day1]+FI_FL[day_SOW_FL+day1]+FL_SD[j]) && i5 == 0){
      gddP[5] <- gdd[i]
      target[5] <- FL_SD[j]
      old.gdd5 <- gdd[i] - (SOW_VE+VE_JUV+JUV_FI[day_SOW_FI + day1]+FI_FL[day_SOW_FL+day1])
      day_SOW_SD <- i
      i5 <- 1
    }
    ## This is for the sixth phase, ends at END seed fill
    if(gdd[i] >= (SOW_VE+VE_JUV+JUV_FI[day_SOW_FI + day1]+FI_FL[day_SOW_FL+day1]+FL_SD[day_SOW_SD+day1]+SD_END[j]) && i6 == 0){
      gddP[6] <- gdd[i]
      target[6] <- SD_END[j]
      old.gdd6 <- gdd[i] - (SOW_VE+VE_JUV+JUV_FI[day_SOW_FI + day1]+FI_FL[day_SOW_FL+day1]+FL_SD[day_SOW_SD+day1])
      day_SOW_END <- i
      i6 <- 1
    }
    ## This is for the seventh phase, ends at PM
    if(gdd[i] >= (SOW_VE+VE_JUV+JUV_FI[day_SOW_FI + day1]+FI_FL[day_SOW_FL+day1]+FL_SD[day_SOW_SD+day1]+SD_END[day_SOW_END + day1]+END_PM)
       && i7 == 0){
      gddP[7] <- gdd[i]
      target[7] <- END_PM
      old.gdd7 <- gdd[i] - (SOW_VE+VE_JUV+JUV_FI[day_SOW_FI + day1]+FI_FL[day_SOW_FL+day1]+FL_SD[day_SOW_SD+day1]+SD_END[day_SOW_END + day1])
      day_SOW_PM <- i 
      i7 <- 1
    }
    
    k <- k + 1
    j <- j + 1
    days[i] <- k  # count number of days needed to complete each phase
     
  }
  days_SOW_PM <- c(day_SOW_VE, day_SOW_JUV, day_SOW_FI, day_SOW_FL, day_SOW_SD, day_SOW_END, day_SOW_PM)
  gddP_phase <- c(old.gdd1, old.gdd2, old.gdd3, old.gdd4, old.gdd5, old.gdd6, old.gdd7)
  names(days_SOW_PM) <- c("VE","JUV","FI","FL","SD","END","PM")

  return(list(days=days, gdd=gdd, gddP=gddP, gddP_phase=gddP_phase, target=target, photothermal=photothermal,
              day_SOW_VE=day_SOW_VE, day_SOW_JUV=day_SOW_JUV, day_SOW_FI=day_SOW_FI,
              day_SOW_FL=day_SOW_FL, day_SOW_SD=day_SOW_SD, day_SOW_END=day_SOW_END,
              day_SOW_PM=day_SOW_PM, days_SOW_PM=days_SOW_PM, gdd_SOW_VE))
}







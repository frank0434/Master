##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title build_params

##' @return
##' @author frank0434
##' @export
build_params <- function(params, Site, SDs, Layer, DT, blukdensity = BDs) {
  
  stopifnot(data.table::is.data.table(DT))
  stopifnot(data.table::is.data.table(blukdensity))
  # BD 
  para1.Low <- blukdensity[Experiment == Site & 
                              Depth == Layer][["Low"]]/1000
  para1.High <- blukdensity[Experiment == Site & 
                               Depth == Layer][["High"]]/1000
  
  ## Treatments 

  ## DUL and LL - From Richard PhD Expt
  para2.Low <- DT[Experiment == Site & 
                    SowingDate == SDs & 
                    Depth == Layer][["Low.DUL"]]
  para2.High <- DT[Experiment == Site & 
                     SowingDate == SDs & 
                     Depth == Layer][["High.DUL"]]
  
  para3.Low <- DT[Experiment == Site & 
                    SowingDate == SDs & 
                    Depth == Layer][["Low.LL"]]
  para3.High <- DT[Experiment == Site & 
                     SowingDate == SDs & 
                     Depth == Layer][["High.LL"]]
  ## SKL, KLR and RFV # From Edmar et al 2018
  para4.Low <- 0.01 
  para4.High <- 0.11
  
  para5.Low <- 0.0005 
  para5.High <- 0.01
  
  para6.Low <- 5
  para6.High <- 70
  
  low <- ls(pattern = ".+Low$")
  high <- ls(pattern = ".+High$")
  para.low <- as.numeric(unlist(mget(low)))
  
  para.high <- as.numeric(unlist(mget(high)))
  para.list <- list(para.low, para.high)
  names(para.list) <- paste0(paste0(Site,"_", SDs, "_", "Layer", Layer),
                             c(".Low", ".High"))
  return(para.list)
}

# build_params(params = parammeters, Site = Site,  SDs, Layer = 1L, DUL_LL_range)

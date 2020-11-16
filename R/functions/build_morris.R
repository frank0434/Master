##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title build_models

##' @return
##' @author frank0434
##' @export
##' @import sensitivity
build_models <- function(params = parameters, 
                         paths = path,
                         para.low, para.high,
                         meta = names(params_ranges)) {
  
  apsimMorris<-morris(model=NULL
                      ,params #string vector of parameter names
                      ,paths #no of paths within the total parameter space
                      ,design=list(type="oat",levels=21,grid.jump=5)
                      ,binf=para.low #min for each parameter
                      ,bsup=para.high #max for each parameter
                      ,scale=T
  )
  sampledValus <- as.data.frame(apsimMorris$X)
  # Add the experiment, sowing dates and layer information for Quality checks
  sampledValus$meta <- gsub("\\..+$", "", meta[1])
  return(sampledValus)
  
}


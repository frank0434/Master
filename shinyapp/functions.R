#' simulation_query
#'
#' @param pool 
#' @param variable 
#' @param pixel_df 
#' @param factor_inputs 
#' @param discreteValues 
#'
#' @return
#' @export
#'
#' @examples
simulation_query <- function(pool,
                             
                             factor) {
  
  # debug
  # factor_inputs <- meta[Experiment == "Iversen12" & SowingDate == "SD1"] %>% as.list()
  # pool <- poolConnection
  shinyjs::show(id = "loading-page")
  print("Running simulation Query")
  sql <- ""
  simulation_df <- NULL
  tryCatch({
      # sql <- paste0("select simulation_id, pixel_id, ", 
      # 							'"',variable, '", year',
      # 						 ' from "Report" where 1=1')
      sql <- paste0('select * from "Report" where 1=1')
      limitSql <- "and \"%s\" in ('%s')"
      sql <- paste(sql, sprintf(limitSql, "Experiment", factor$Experiment))
      sql <- paste(sql, sprintf(limitSql, "SowingDate", factor$SowingDate))
      
      sql <- paste(sql, sprintf(limitSql, "SKL", factor$SKL))
      sql <- paste(sql, sprintf(limitSql, "KLR", factor$KLR))
      sql <- paste(sql, sprintf(limitSql, "RFV", factor$RFV), ";")
      
      

      cat(sql)
      simulation_df <- pool %>%
        dbGetQuery(sql) %>%
        collect()
      },
  
  error = function(e) NULL,
  finally={
    hide(id = "loading-page")
  })
  
  #validate(need(nrow(df)>0,'Scenario not available. Please select again.'))
  if(is.null(simulation_df) || nrow(simulation_df) == 0){
    print('Scenario not available. Please select again.')
    return(NULL)
  }
  
  # print("before return")
  print(head(simulation_df))
  return(data.table::as.data.table(simulation_df))
}


# Plotting ----------------------------------------------------------------

#' linechasedot
#' @description VISUALISE the simulation value as lines and observation value 
#' as dot. 
#'
#' @param DTsims 
#' @param DTobs 
#' @param DUL_LL_range 
#' @param Experiment 
#' @param SowingDate 
#' @param Depth 
#'
#' @return
#' @export
#'
#' @examples
linechasedot <- function(DTsims, DTobs, DUL_LL_range, 
                         Expt, SD, Layer){
  point_size <- 6
  SE1 <- DUL_LL_range[Experiment == Expt & 
                        SowingDate == SD & 
                        Depth == Layer]
  setnames(SE1, "Clock.Today.DUL", "Clock.Today")
  cols <- c("Clock.Today", "SKL", "KLR", "RFV",
            paste0("SWmm.", Layer, "."),
            paste0("DULmm.", Layer, "."),
            paste0("LL15mm.", Layer, "."))
  p <- DTsims[,..cols] %>% 
    ggplot(aes(Clock.Today)) +
    geom_hline(aes_string(yintercept = paste0("DULmm.", Layer, ".")), color = "blue") +
    geom_hline(aes_string(yintercept = paste0(" LL15mm.", Layer, ".")), color = "blue") +
    geom_line(aes_string(y = paste0("SWmm.", Layer, ".")), color = "grey",  alpha = 0.5) +
    geom_point(data = DTobs, aes_string(y = paste0("SWmm.", Layer, "..mean")), color = "red",size = point_size) +
    geom_errorbar(data = SE1, aes(ymin = DUL - SE, ymax = DUL + SE), 
                  show.legend = TRUE, width = 8, size = 1.5) + 
    ggtitle(paste0(Expt, SD)) +
    scale_x_date(date_labels = "%Y %b", date_breaks = "4 weeks") +
    
    # scale_color_manual(name = "", values = palette()) +
    scale_color_manual(name = "", label = c("Simulation", "Observation"), 
                       values = c("grey", "red")) +
    theme_classic() +
    theme(legend.position =  c(.5, .2),
          axis.text = element_text(angle = 30, hjust = 1,size = 14),
          text = element_text(size = 16))
  return(p)
}

obsVSsims <- function(DTsims, DTobs, 
                      Expt, SD, Layer){
  point_size <- 3
  cols <- c("Clock.Today", "SKL", "KLR", "RFV",
            paste0("SWmm.", Layer, "."),
            paste0("DULmm.", Layer, "."),
            paste0("LL15mm.", Layer, "."))
  DT <- merge.data.table(DTsims[,..cols], 
                         DTobs,
                         by = c( "Clock.Today"), 
                         all = TRUE)
  p <- DT %>% 
    ggplot(aes_string(x = paste0("SWmm.", Layer, "..mean"),y = paste0("SWmm.", Layer, "."))) +
    geom_point(color = "grey", size = point_size, alpha = 0.5) +
    geom_smooth(method = "lm", color = "red") + 
    geom_abline()+
    ggtitle(paste0(Expt, SD)) +
    theme_classic() +
    theme(legend.position =  c(.5, .2),
          axis.text = element_text(angle = 30, hjust = 1,size = 14),
          text = element_text(size = 20)) 
  return(p)
}

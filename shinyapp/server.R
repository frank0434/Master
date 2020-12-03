server <- function(input, output, session) {
  hide(id = "loading-page")
  values <- reactiveValues()
  
  #######################
  # Database Connection #
  #######################
  
  # get DB cred
  dbcred <- reactive({
    validate(need(input$project != "","no project selected"))
    get(input$project)
  })
  filename <- reactive({
    best_comb()$filename
  })
  # set up connection pool
  pool <- reactive({

    poolConnection <<- DBI::dbConnect(drv = RSQLite::SQLite(), filename())
    validate(need(try(dbIsValid(poolConnection)), "Database connection is not vaild"))
    return(poolConnection)
  })
  
  ##############################
  # Cache all the small tables #
  ##############################
  
  ### project table
  # proj_df <- reactive({
  #   pj_df <- pool() %>% tbl("Project") %>% collect()
  #   if("lat" %in% names(pj_df)){
  #     pj_df <- rename(pj_df,
  #                     Lat = lat,
  #                     Lon = lon)
  #   }
  #   return(pj_df)
  #   
  # })
  expt <- reactive({input$Experiment})
  sd <- reactive({input$sowingdate})
  SowingDate <- reactive({
    DT <- meta[Experiment == expt()
               ][, SDorder := as.integer(gsub("SD", "", SowingDate))
                 ][order(SDorder)]
    
  })
  factor_inputs <- reactive({
    list <- best_comb() %>% 
      as.list()
    names(list) <- colnames(best_comb())
    list
    
  })
 
  ############################
  # update drop down choices #
  ############################
  
  observe({
    updateSelectInput(session, "sowingdate", choices = SowingDate()$SowingDate)
    # settingInputNames <- build_factor_dropdowns(factor_df(), "ref", "1", pool())
    # updateSelectInput(session, "xcol", choices = c(names(unlist(inputname_list_ref)),var_list()), selected = var_list()[1])
  })

  
  ##################################################
  # query db table and update reactive dfs #
  ##################################################
  
  best_comb <- reactive({
    meta[Experiment == expt() & SowingDate == sd()]
  })
  
  report <- reactive({
    DT = DBI::dbReadTable(conn = pool(), "Report")
    # DBI::dbDisconnect(pool())
    DT = data.table::as.data.table(DT)
    DT = DT[order(SimulationID)][, ':='(Clock.Today =as.Date(Clock.Today))]
  })
  
  obs <- reactive({
    DT = DBI::dbReadTable(conn = pool(), "Observed", check.names = FALSE)
    # DBI::dbDisconnect(pool())
    DT = data.table::as.data.table(DT)
    cols1 <- paste0("SW(", 1:22, ")")
    DT$PSWC <- rowSums(DT[, ..cols1])
    DT[, ':='(Clock.Today =as.Date(Clock.Today))]
    DT
   
  })


  #####################
  # Output parameters #
  #####################
  output$best_parameters <- DT::renderDataTable({
    tab <- DT::datatable(best_comb(),
                         escape = FALSE,
                         options = list(dom = 't',
                                        columnDefs = list(list(className = 'dt-left', targets = '_all'))),
                         rownames = FALSE, caption = "The best fit parameter combination." )
    
    })
  
  output$best_df <- DT::renderDataTable({
    tab <- DT::datatable(report(),
                         escape = FALSE,
                         options = list(dom = 't',
                                        columnDefs = list(list(className = 'dt-left', targets = '_all'))),
                         rownames = FALSE, caption = "The best fit parameter combination." )
    
  })
  output$factors <- renderText({unlist(factor_inputs())})

# output observation to ui ------------------------------------------------
  output$observation <- DT::renderDataTable({
    tab <- DT::datatable(obs(),
                         escape = FALSE,
                         options = list(dom = 't',
                                        columnDefs = list(list(className = 'dt-left', targets = '_all'))),
                         rownames = FALSE, caption = "The best fit parameter combination." )
  })

# output simulation to ui -------------------------------------------------
  output$simulation <- DT::renderDataTable({
    tab <- DT::datatable(report(),
                         escape = FALSE,
                         options = list(dom = 't',
                                        columnDefs = list(list(className = 'dt-left', targets = '_all'))),
                         rownames = FALSE, caption = "The best fit parameter combination." )
  })
  #################
  # Output Graphs #
  #################
  keys <- reactive({
    keys <- c( "SimulationID", "KLR", "RFV", "SKL")
    
  })
  palette <- reactive({
    SimID <- unique(report()$SimulationID)
    palette <- rep("grey80", times = length(SimID))
    palette_named <- setNames(palette,  SimID)
    
    palette_named[best_comb()$SimulationID] = "red"
    palette_named
  
    })
  
  # diff of rasters
  output$SKL_withAll <- renderPlot({
    point_size <- 6
    boundaries <- c(unique(report()$DULmm), unique(report()$LL15mm))
    cols <- c(keys(), "Clock.Today","PSWC", "DULmm", "LL15mm")
    report()[, ..cols
             ] %>% 
      ggplot(aes(Clock.Today)) +
      geom_line(aes(y = PSWC, color = "grey"),  size = 1,alpha = 0.5) +
      # geom_line(data = report()[SimulationID == best_comb()$SimulationID], 
      #           aes(y = PSWC),
      #           color = "red",size = point_size,  alpha = 0.7) +
      geom_point(data = obs(), aes(y = PSWC, color = "red"), size = point_size, 
                 alpha = 0.9) +
      ggtitle(paste0(expt(), sd())) +
      scale_x_date(date_labels = "%Y %b", date_breaks = "6 weeks") +
      geom_hline(yintercept = boundaries, color = "blue") + 
      # scale_color_manual(name = "", values = palette()) +
      theme_classic() +
      theme(legend.position =  c(.5, .2),
            axis.text = element_text(angle = 30, hjust = 1,size = 14),
            text = element_text(size = 20)) + 
      scale_color_manual(name = "", label = c("Simulation", "Observation"), 
                         values = c("grey", "red")) 
  })
  output$obs_withAll <- renderPlot({
    point_size <- 2
    
    cols <- c(keys(), "Clock.Today","PSWC", "DULmm", "LL15mm")
    DT <- merge.data.table(report()[, ..cols], obs(),
                           by = c( "Clock.Today"), 
                           all = TRUE, suffixes = c(".sim", ".obs"))
    DT %>% 
      ggplot(aes(x = PSWC.obs,y = PSWC.sim )) +
      geom_point(color = "grey", size = 3, alpha = 0.5) +
      geom_smooth(method = "lm", color = "red") + 
      geom_abline()+
      ggtitle(paste0(expt(), sd())) +
      theme_classic() +
      theme(legend.position =  c(.5, .2),
            axis.text = element_text(angle = 30, hjust = 1,size = 14),
            text = element_text(size = 20)) 
  })
}

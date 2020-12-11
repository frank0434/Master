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
  
  expt <- reactive({input$Experiment})
  sd <- reactive({input$sowingdate})

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
    updateSelectInput(session, "sowingdate", choices = SowingDate)
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
    data.table::setkey(DT, SimulationID)
    DT = DT[, ':='(Clock.Today =as.Date(Clock.Today))]
  })
  
  obs <- reactive({
    DT = DBI::dbReadTable(conn = pool(), "Observed")
    # DBI::dbDisconnect(pool())
    DT = data.table::as.data.table(DT)
    cols1 <- paste0("SWmm.", 1:22,"..mean")
    DT$PSWC <- rowSums(DT[, ..cols1])
    DT[, ':='(Clock.Today =as.Date(Clock.Today))]
    DT
   
  })


  #####################
  # Output parameters #
  #####################
  # output$best_parameters <- DT::renderDataTable({
  #   tab <- DT::datatable(best_comb(),
  #                        escape = FALSE,
  #                        options = list(dom = 't',
  #                                       columnDefs = list(list(className = 'dt-left', targets = '_all'))),
  #                        rownames = FALSE, caption = "The best fit parameter combination." )
  #   
  #   })
  
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
# line chase dots ---------------------------------------------------------

  output$SKL_withAll <- renderPlot({
    point_size <- 6
    boundaries <- unlist(report()[1, .(DULmm, LL15mm)])
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

# sims vs obs -------------------------------------------------------------
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
  

# surface  ----------------------------------------------------------------
  output$surface <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 1)
  })
  output$surface_ObsVSSims <- renderPlot({
    obsVSsims(DTsims = report(), DTobs = obs(),
              Expt = expt(), SD = sd(), Layer = 1)
  })
  output$surface2 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 2)
  })
  output$surface_ObsVSSims2 <- renderPlot({
    obsVSsims(report(), obs(),
                 Expt = expt(), SD = sd(), Layer = 2)
  })
  output$surface3 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 3)
  })
  output$surface_ObsVSSims3 <- renderPlot({
    obsVSsims(report(), obs(), 
                 Expt = expt(), SD = sd(), Layer = 3)
  })
  output$surface4 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 4)
  })
  output$surface_ObsVSSims4 <- renderPlot({
    obsVSsims(report(), obs(), 
                 Expt = expt(), SD = sd(), Layer = 4)
  })  
  output$surface5 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 5)
  })
  output$surface_ObsVSSims5 <- renderPlot({
    obsVSsims(report(), obs(), 
                 Expt = expt(), SD = sd(), Layer = 5)
  })  
  output$surface6 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 6)
  })
  output$surface_ObsVSSims6 <- renderPlot({
    obsVSsims(report(), obs(), 
                 Expt = expt(), SD = sd(), Layer = 6)
  })  
  output$surface7 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 7)
  })
  output$surface_ObsVSSims7 <- renderPlot({
    obsVSsims(report(), obs(), 
                 Expt = expt(), SD = sd(), Layer = 7)
  })  
  output$surface8 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 8)
  })
  output$surface_ObsVSSims8 <- renderPlot({
    obsVSsims(report(), obs(),  
                 Expt = expt(), SD = sd(), Layer = 8)
  })  
  output$surface9 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 9)
  })
  output$surface_ObsVSSims9 <- renderPlot({
    obsVSsims(report(), obs(),
                 Expt = expt(), SD = sd(), Layer = 9)
  }) 
  output$surface10 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 10)
  })
  output$surface_ObsVSSims10 <- renderPlot({
    obsVSsims(report(), obs(),
                 Expt = expt(), SD = sd(), Layer = 10)
  })
  output$surface11 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 11)
  })
  output$surface_ObsVSSims11 <- renderPlot({
    obsVSsims(DTsims = report(), DTobs = obs(),
              Expt = expt(), SD = sd(), Layer = 11)
  })
  output$surface12 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 12)
  })
  output$surface_ObsVSSims12 <- renderPlot({
    obsVSsims(report(), obs(),
              Expt = expt(), SD = sd(), Layer = 12)
  })
  output$surface13 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 13)
  })
  output$surface_ObsVSSims13 <- renderPlot({
    obsVSsims(report(), obs(), 
              Expt = expt(), SD = sd(), Layer = 13)
  })
  output$surface14 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 14)
  })
  output$surface_ObsVSSims14 <- renderPlot({
    obsVSsims(report(), obs(), 
              Expt = expt(), SD = sd(), Layer = 14)
  })  
  output$surface15 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 15)
  })
  output$surface_ObsVSSims15 <- renderPlot({
    obsVSsims(report(), obs(), 
              Expt = expt(), SD = sd(), Layer = 15)
  })  
  output$surface16 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 16)
  })
  output$surface_ObsVSSims16 <- renderPlot({
    obsVSsims(report(), obs(), 
              Expt = expt(), SD = sd(), Layer = 16)
  })  
  output$surface17 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 17)
  })
  output$surface_ObsVSSims17 <- renderPlot({
    obsVSsims(report(), obs(), 
              Expt = expt(), SD = sd(), Layer = 17)
  })  
  output$surface18 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 18)
  })
  output$surface_ObsVSSims18 <- renderPlot({
    obsVSsims(report(), obs(),  
              Expt = expt(), SD = sd(), Layer = 18)
  })  
  output$surface19 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 19)
  })
  output$surface_ObsVSSims19 <- renderPlot({
    obsVSsims(report(), obs(),
              Expt = expt(), SD = sd(), Layer = 19)
  }) 
  output$surface20 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 20)
  })
  output$surface_ObsVSSims20 <- renderPlot({
    obsVSsims(report(), obs(),
              Expt = expt(), SD = sd(), Layer = 20)
  } )
  output$surface21 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 21)
  })
  output$surface_ObsVSSims21 <- renderPlot({
    obsVSsims(report(), obs(),
              Expt = expt(), SD = sd(), Layer = 21)
  }) 
  output$surface22 <- renderPlot({
    linechasedot(report(), obs(), DUL_LL_range, 
                 Expt = expt(), SD = sd(), Layer = 22)
  })
  output$surface_ObsVSSims22 <- renderPlot({
    obsVSsims(report(), obs(),
              Expt = expt(), SD = sd(), Layer = 22)
  } )

}

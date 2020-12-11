source("global.R")
source("functions.R")

ui <- fluidPage(
  theme = "style.css",
  useShinyjs(),
  
  # loading indicator
  # div(
  #   id="loading-page",
  #   span(id="loading-box",
  #        h2("Loading..."),
  #        img(src = "ajax-loader-bar.gif", class = "spinner")
  #   )
  # ),
  
  #	headerPanel('Discovery Science | Spatial Analysis | Crops'),
  headerPanel("Frank\'s Master Toy Tool"),
  p(),
  
  # Side panel details
  sidebarLayout(
    sidebarPanel(
      
      width = 3,
    selectInput('Experiment', label = "Experiment", choices = c(experiments)),
  
    selectInput('sowingdate', label = "Sowing Date", choices = c(SowingDate), selected = 1),
    tags$hr(),
    # actionButton("updateScenarios", "Update", style="align: center;background-color: orange;position:-webkit-sticky;position:sticky;top:0px;  width:inherit; width: 100%; z-index: 999; height: 50px; font-size: 150%"),
    # h4(tags$b("Construct parameters:")),
    # selectInput('SKL',label = "Surface kl", choices = c(meta$SKL, "All")),
    # selectInput('KLR',label = "kl Reduction Factor", choices = c(meta$KLR, "All")),
    # selectInput('RFV',label = "Root Front Velocity", choices = c(meta$RFV, "All")),
    tags$hr()
   
  ), 
  mainPanel(
    tabsetPanel(
      tabPanel("Overall PSWC",
               DT::dataTableOutput("best_parameters"),
               plotOutput("SKL_withAll"),
               # DT::dataTableOutput("best_df", width = 10)
               # textOutput("factors")
               plotOutput("obs_withAll")
               ), 

# Detail in each layer ----------------------------------------------------

      tabPanel("0-20cm",
               plotOutput("surface"),
               plotOutput("surface_ObsVSSims")
               ),
      tabPanel("20-30cm",
               plotOutput("surface2"),
               plotOutput("surface_ObsVSSims2")),
      tabPanel("30-40cm",
               plotOutput("surface3"),
               plotOutput("surface_ObsVSSims3")),
      tabPanel("40-50cm",
               plotOutput("surface4"),
               plotOutput("surface_ObsVSSims4")),
      tabPanel("50-60cm",
               plotOutput("surface5"),
               plotOutput("surface_ObsVSSims5")),
      tabPanel("60-70cm",
               plotOutput("surface6"),
               plotOutput("surface_ObsVSSims6")),
      tabPanel("70-80cm",
               plotOutput("surface7"),
               plotOutput("surface_ObsVSSims7")),
      tabPanel("80-90cm",
               plotOutput("surface8"),
               plotOutput("surface_ObsVSSims8")),
      tabPanel("90-100cm",
               plotOutput("surface9"),
               plotOutput("surface_ObsVSSims9")),
      tabPanel("100-110cm",
               plotOutput("surface10"),
               plotOutput("surface_ObsVSSims10")),
    tabPanel("210-220cm",
             plotOutput("surface11"),
             plotOutput("surface_ObsVSSims11")),
    tabPanel("120-130cm",
             plotOutput("surface12"),
             plotOutput("surface_ObsVSSims12")),
    tabPanel("130-140cm",
             plotOutput("surface13"),
             plotOutput("surface_ObsVSSims13")),
    tabPanel("140-150cm",
             plotOutput("surface14"),
             plotOutput("surface_ObsVSSims14")),
    tabPanel("150-160cm",
             plotOutput("surface15"),
             plotOutput("surface_ObsVSSims15")),
    tabPanel("160-170cm",
             plotOutput("surface16"),
             plotOutput("surface_ObsVSSims16")),
    tabPanel("170-180cm",
             plotOutput("surface17"),
             plotOutput("surface_ObsVSSims17")),
    tabPanel("180-190cm",
             plotOutput("surface18"),
             plotOutput("surface_ObsVSSims18")),
    tabPanel("190-200cm",
             plotOutput("surface19"),
             plotOutput("surface_ObsVSSims19")),
    tabPanel("200-210cm",
             plotOutput("surface20"),
             plotOutput("surface_ObsVSSims20")),
    tabPanel("210-220cm",
             plotOutput("surface21"),
             plotOutput("surface_ObsVSSims21")),
    tabPanel("220-230cm",
             plotOutput("surface22"),
             plotOutput("surface_ObsVSSims22")),

      tabPanel("DataTables", 
               DT::dataTableOutput("observation"),
               DT::dataTableOutput("simulation")
               # DT::dataTableOutput("best_df")
               )
    )
    
  ))
)
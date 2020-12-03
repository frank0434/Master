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
      tabPanel("0-20cm",
               plotOutput("surface"),
               plotOutput("surface_ObsVSSims")), 
      tabPanel("DataTables", 
               DT::dataTableOutput("observation"),
               DT::dataTableOutput("simulation")
               # DT::dataTableOutput("best_df")
               )
    )
    
  ))
)
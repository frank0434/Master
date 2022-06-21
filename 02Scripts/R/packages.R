library(data.table)
library(readxl)
library(magrittr)
# library(forcats)
# library(lubridate)
library(DBI)
library(RSQLite)
# library(RPostgreSQL)
# library(inspectdf)
# library(DataExplorer)
# library(reticulate)
# library(visNetwork) 
# library(naniar)
# library(viridis)
library(openxlsx)
# library(checkpoint)
# library(knitr)
# library(pander)
library(ggplot2)
# library(cowplot)
# library(latex2exp)
# library(zoo)
# library(broom)
# library(dplyr)
# library(tidyr)
library(kableExtra)
<<<<<<< HEAD
=======
library(tabulizer)
# library(bookdown)
>>>>>>> e56f7e4... env updates
library(here)

# Workflow control 
library(targets)
library(tarchetypes)
library(future)
library(future.callr)
library(future.batchtools)

# Stats

library(hydroGOF)
library(DEoptim)
# Customised package
library(autoapsimx)
library(mcp)
potentialPKGS <- c("autoapsimx","clipr"
,"dplyr     ","drake     "
,"DT        ","ggthemes  "
,"ggvis     ","inspectdf "
,"lubridate ","pool      "
,"purrr     ","readr     "
,"reticulate","RPostgreSQL"
,"shiny     ","shinyjs   "
,"tidyr     ","visNetwork")
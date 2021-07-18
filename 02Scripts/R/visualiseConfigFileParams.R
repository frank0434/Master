

# Aim
# Graph the fitted values over treatment 

filepath <- list.files("01Data/ProcessedData/ConfigurationFiles/",
                       full.names = TRUE)

list_files <- sapply(filepath, readLines, USE.NAMES = TRUE, simplify = FALSE)
info <- lapply(list_files, function(x){
  treatment <- x[1]
  values <- x[17:25]
  dt <- data.table(SowingDate = treatment, 
                   info = values)
  }
  )
DT <- rbindlist(info)
DT[, (c("variable", "value")) := tstrsplit(info, split = "=")]
DT[, value := as.numeric(value)]
DT[, SowingDate:=gsub(".+= |SowingDate", "", SowingDate)]
DT %>% 
  ggplot(aes(value)) +
  geom_histogram()+
  facet_wrap(~ variable, scales = "free_x")


DT %>% 
  ggplot(aes(SowingDate, value)) +
  geom_point()+
  facet_wrap(~ variable, scales = "free_y") +
  theme_classic()+
  theme(axis.text.x = element_text(angle = 90))


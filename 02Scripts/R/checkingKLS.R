dt <- readxl::read_excel("01Data/BDandkl.xlsx") 
dt <- data.table::as.data.table(dt)


source('02Scripts/R/packages.R')
DT <- dt[,lapply(.SD, as.numeric)]
DT %>% 
  ggplot(aes(x = Depth))+
  geom_line(aes(y = AshleyDene, color = "AD"))+
  geom_line(aes(y = Iversen12, color = "I12"))+
  scale_x_reverse()+
  scale_color_manual(values = c("#0000ff","#ff0000"))+
  coord_flip() +
  theme_classic() +
  labs(y = bquote("BD g cm"^"-3"))+
  theme(text = element_text(size = 20))


KLS <- DT %>% 
  melt.data.table(id.vars = c("Depth", "AshleyDene", "Iversen12"), 
                  variable.factor = FALSE)
  
KLS %>% 
  ggplot(aes(x = Depth))+
  geom_line(aes(y = value))+
  geom_point(aes(y = value))+
  scale_x_reverse()+
  # scale_color_manual(values = c("#0000ff","#ff0000"))+
  coord_flip() +
  theme_classic() +
  facet_wrap( ~ variable)+
  labs(y = bquote("kl mm day"^"-1"))+
  theme(text = element_text(size = 20))

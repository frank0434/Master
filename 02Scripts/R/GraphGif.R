library(magick)

manual1 <- image_read('./05figures/klEDA/plot_Site_SD_AshleyDene_SD1.png' )

manual2 <- image_read('./05figures/klEDA/plot_Site_SD_AshleyDene_SD2.png' )

AD <- list.files(path='./05figures/klEDA/', pattern = 'plot_Site_.+._Ash.*.png', full.names = TRUE)
AD <- AD[c(1, 3:10,2)]
l_AD <- image_read(AD)


l = image_join(l_AD)
l = image_animate(l, fps=0.5)

image_write_gif(l, "AD.gif") 


# I12 ---------------------------------------------------------------------


I12 <- list.files(path='./05figures/klEDA/', pattern = 'plot_Site_.+._Ive.*.png', full.names = TRUE)
# I12 <- I12[c(1, 3:8,2)]
l_I12 <- image_read(I12)


l = image_join(l_I12)
l = image_animate(l, fps=0.5)

image_write_gif(l, "I12.gif") 

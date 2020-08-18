
library(roll)
n = 11

  X = ADSD2[Depth == n]$DAS
  y = ADSD2[Depth == n]$relativeSW
  lms = roll_lm(X, y, width = 3)
  lmlayer1 = cbind(lms$coefficients, lms$r.squared, lms$std.error, X) 
  colnames(lmlayer1) = c("Intercept", "coef", "R2", "Intercept_sem", "sem", "DAS")
  critical = qt(0.05, df = 460) # How to decide this df? totoal df in one treatment?
  CI = as.data.table(lmlayer1)[, ci := coef - critical * sem]
  thechooseone = CI[coef < 0 & coef < ci ]
  # thechooseone = lmlayer1[x1<CI][1] # not a good standard
  # t.test(lmlayer1$x1, mu =  0)
  plot(X, y)
  lines(X, y)
  abline(v = thechooseone$DAS, col = "red")




## Test



set.seed(32981054)
n <- 100
p <- 6
wdth = 5
X <- matrix(rnorm(p * n), n, p)
y <- drop(X %*% runif(p)) + rnorm(n)
df <- data.frame(y, X)
frm <- eval(parse(text = paste0(
  "formula(y ~ -1 + ", paste0("X", 1:p, collapse = " + "), ")")))
frm
library(rollRegres)
roll_regress_R_for_loop <- function(X, y, width){
  n <- nrow(X)
  p <- ncol(X)
  out <- matrix(NA_real_, n, p)
  
  for(i in width:n){
    idx <- (i - width + 1L):i
    out[i, ] <- lm.fit(X[idx, , drop = FALSE], y[idx])$coefficients
  }
  
  out
}
base_res <- roll_regress_R_for_loop(X, y, wdth)
base_res
?roll_regres
n = length(ADSD2[Depth == 3]$DAS)
width = 3
n = 5:10

l3 = lm(X ~ y)
l3$coefficients
plot(l3)
l3$fitted.values
plot(X,y)
lines(l3$fitted.values)
library(roll)
X = ADSD2[Depth == 1]$DAS
y = ADSD2[Depth == 1]$SW
roll3 = roll_lm(X, y, width = 3)
roll3$coefficients %>% 
  as.data.table(keep.rownames = TRUE)%>% 
  ggplot(aes(1:22,  x1)) +
  geom_line()

layer3 = ADSD2[Depth == 11]
  
  Lines <- "  bo_m          dax             bo_m_lag
 -0.040131270  0.001842860      0.032612438
  0.112425025 -0.018043681     -0.040131270
 -0.078987920 -0.009463752      0.112425025
 -0.011990692  0.020144077     -0.078987920
 -0.005279136  0.013360796     -0.011990692
  0.055994660 -0.004568196     -0.005279136
"

# library(zoo)
g <- read.table(text = Lines,  header = TRUE)
dolm <- function(x) {
  co <- coef(summary(lm(SW ~ DAS, as.data.frame(x))))
  c(Est = co[, 1], SE = co[, 2], t = co[, 3], P = co[, 4])
}

r <- rollapply(layer3, 3, dolm)
r
g
coef(summary(lm(SW ~ DAS, as.data.frame(layer3))))
seat <- as.zoo(log(UKDriverDeaths))
time(seat) <- as.yearmon(time(seat))
seat <- merge(y = seat, y1 = lag(seat, k = -1),
              y12 = lag(seat, k = -12), all = FALSE)
seat
rr <- rollapply(seat, width = 36,
                FUN = function(z) coef(lm(y ~ y1 + y12, data = as.data.frame(z))),
                by.column = FALSE, align = "right")
plot(rr)

rr3 = rollapply(layer3, width = 4,
          FUN = function(z) coef(lm(SW ~ DAS, data = as.data.frame(z))),
          by.column = FALSE, align = "right")
rr3
plot(rr3)

coef(lm(SW ~ DAS, data = layer3))
rr3





layer3

coef(summary(lm(SW ~ DAS, layer3[1:3,])))
coef(summary(lm(SW ~ DAS, layer3[2:4,])))
coef(summary(lm(SW ~ DAS, layer3[3:5,])))
coef(summary(lm(SW ~ DAS, layer3[4:6,])))
coef(summary(lm(SW ~ DAS, layer3[5:7,])))
coef(summary(lm(SW ~ DAS, layer3[6:8,])))
coef(summary(lm(SW ~ DAS, layer3[7:9,])))
coef(summary(lm(SW ~ DAS, layer3[8:10,])))
coef(summary(lm(SW ~ DAS, layer3[9:11,])))

coef(summary(lm(SW ~ DAS, layer3[10:12,])))


roll_coef <- function(x){
  X = x$DAS
  y = x$SW
  lms = roll_lm(X, y, width = 3)
  lmlayer1 = cbind(lms$coefficients, lms$r.squared, X) %>% 
    as.data.table(keep.rownames = TRUE)
  lmlayer1
}
ADSD2
nested = ADSD2[, list(data = list(.SD)), by = .(Experiment, SowingDate, Depth)]
nested[, data:= lapply(data, roll_coef)]
dt = nested[, unlist(data, recursive = FALSE), by = .(Experiment, SowingDate, Depth)]

dt%>% 
  ggplot(aes(x1)) +
  geom_histogram()

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

X = ADSD2[Depth == 3]$DAS
y = ADSD2[Depth == 3]$SW
roll3 = roll_lm(X, y, width = 3)
roll3$coefficients %>% 
  as.data.table(keep.rownames = TRUE)%>% 
  ggplot(aes(1:22,  x1)) +
  geom_line()

rm(list = ls())
source("R/FData.R")
source("R/ModelSTMoE.R")
source("R/ModelLearner.R")


# Building matrices for regression
load("data/simulatedTimeSeries.RData")
fData <- FData$new()
fData$setData(X, Y)


K <- 2 # number of regimes (mixture components)
p <- 1 # dimension of beta (order of the polynomial regressors)
q <- 1 # dimension of w (order of the logistic regression: to be set to 1 for segmentation)

modelSTMoE <- ModelSTMoE(fData, K, p, q)

n_tries <- 1
max_iter = 1500
threshold <- 1e-5
verbose <- TRUE
verbose_IRLS <- FALSE


####
# EM Algorithm
####
solution <- EM(modelSTMoE, n_tries, max_iter, threshold, verbose, verbose_IRLS)

solution$plot()


<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->
<!-- badges: end -->
Overview
========

User-friendly and flexible algorithm modelling, sampling, inference, and clustering heterogeneous data with the Skew-t Mixture-of-Experts (StMoE) model.

Installation
============

You can install the development version of StMoE from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("fchamroukhi/StMoE")
```

To build *vignettes* for examples of usage, type the command below instead:

``` r
# install.packages("devtools")
devtools::install_github("fchamroukhi/StMoE", 
                         build_opts = c("--no-resave-data", "--no-manual"), 
                         build_vignettes = TRUE)
```

Use the following command to display vignettes:

``` r
browseVignettes("StMoE")
```

Usage
=====

``` r
library(StMoE)
```

``` r
n <- 500 # Size of the sample
alphak <- matrix(c(0, 8), ncol = 1) # Parameters of the gating network
betak <- matrix(c(0, -2.5, 0, 2.5), ncol = 2) # Regression coefficients of the experts
sigmak <- c(0.5, 0.5) # Standard deviations of the experts
lambdak <- c(3, 5) # Skewness parameters of the experts
nuk <- c(5, 7) # Degrees of freedom of the experts network t densities
x <- seq.int(from = -1, to = 1, length.out = n) # Inputs (predictors)

# Generate sample of size n
sample <- sampleUnivSTMoE(alphak = alphak, betak = betak, sigmak = sigmak, 
                          lambdak = lambdak, nuk = nuk, x = x)
y <- sample$y

K <- 2 # Number of regressors/experts
p <- 1 # Order of the polynomial regression (regressors/experts)
q <- 1 # Order of the logistic regression (gating network)

n_tries <- 1
max_iter <- 1500
threshold <- 1e-5
verbose <- TRUE
verbose_IRLS <- FALSE

stmoe <- emStMoE(X = x, Y = y, K, p, q, n_tries, max_iter, 
                 threshold, verbose, verbose_IRLS)
#> EM - StMoE: Iteration: 1 | log-likelihood: -360.918219156259
#> EM - StMoE: Iteration: 2 | log-likelihood: -340.312199740558
#> EM - StMoE: Iteration: 3 | log-likelihood: -336.81199954955
#> EM - StMoE: Iteration: 4 | log-likelihood: -334.678448612944
#> EM - StMoE: Iteration: 5 | log-likelihood: -333.368786304469
#> EM - StMoE: Iteration: 6 | log-likelihood: -332.378651904012
#> EM - StMoE: Iteration: 7 | log-likelihood: -331.416370949352
#> EM - StMoE: Iteration: 8 | log-likelihood: -330.311753264688
#> EM - StMoE: Iteration: 9 | log-likelihood: -328.970616724365
#> EM - StMoE: Iteration: 10 | log-likelihood: -327.36646546389
#> EM - StMoE: Iteration: 11 | log-likelihood: -325.520020780522
#> EM - StMoE: Iteration: 12 | log-likelihood: -323.49157231905
#> EM - StMoE: Iteration: 13 | log-likelihood: -321.361097935629
#> EM - StMoE: Iteration: 14 | log-likelihood: -319.21596748688
#> EM - StMoE: Iteration: 15 | log-likelihood: -317.121529914793
#> EM - StMoE: Iteration: 16 | log-likelihood: -315.129654375853
#> EM - StMoE: Iteration: 17 | log-likelihood: -313.246021403366
#> EM - StMoE: Iteration: 18 | log-likelihood: -311.455445437556
#> EM - StMoE: Iteration: 19 | log-likelihood: -309.704743663328
#> EM - StMoE: Iteration: 20 | log-likelihood: -307.923603673431
#> EM - StMoE: Iteration: 21 | log-likelihood: -306.019731688503
#> EM - StMoE: Iteration: 22 | log-likelihood: -303.901066199451
#> EM - StMoE: Iteration: 23 | log-likelihood: -301.517077133633
#> EM - StMoE: Iteration: 24 | log-likelihood: -298.871583437327
#> EM - StMoE: Iteration: 25 | log-likelihood: -296.033769613469
#> EM - StMoE: Iteration: 26 | log-likelihood: -293.105729159314
#> EM - StMoE: Iteration: 27 | log-likelihood: -290.206753682348
#> EM - StMoE: Iteration: 28 | log-likelihood: -287.445087104632
#> EM - StMoE: Iteration: 29 | log-likelihood: -284.891400022567
#> EM - StMoE: Iteration: 30 | log-likelihood: -282.588998983271
#> EM - StMoE: Iteration: 31 | log-likelihood: -280.538384368292
#> EM - StMoE: Iteration: 32 | log-likelihood: -278.722892569404
#> EM - StMoE: Iteration: 33 | log-likelihood: -277.126497158683
#> EM - StMoE: Iteration: 34 | log-likelihood: -275.718473001408
#> EM - StMoE: Iteration: 35 | log-likelihood: -274.47750494225
#> EM - StMoE: Iteration: 36 | log-likelihood: -273.385692944314
#> EM - StMoE: Iteration: 37 | log-likelihood: -272.424525385644
#> EM - StMoE: Iteration: 38 | log-likelihood: -271.580447029384
#> EM - StMoE: Iteration: 39 | log-likelihood: -270.837718253819
#> EM - StMoE: Iteration: 40 | log-likelihood: -270.183014154754
#> EM - StMoE: Iteration: 41 | log-likelihood: -269.604365407485
#> EM - StMoE: Iteration: 42 | log-likelihood: -269.092069487677
#> EM - StMoE: Iteration: 43 | log-likelihood: -268.638534752714
#> EM - StMoE: Iteration: 44 | log-likelihood: -268.237219536561
#> EM - StMoE: Iteration: 45 | log-likelihood: -267.881642979585
#> EM - StMoE: Iteration: 46 | log-likelihood: -267.566373686613
#> EM - StMoE: Iteration: 47 | log-likelihood: -267.287556449449
#> EM - StMoE: Iteration: 48 | log-likelihood: -267.041240612947
#> EM - StMoE: Iteration: 49 | log-likelihood: -266.823545537698
#> EM - StMoE: Iteration: 50 | log-likelihood: -266.630898066496
#> EM - StMoE: Iteration: 51 | log-likelihood: -266.460485139253
#> EM - StMoE: Iteration: 52 | log-likelihood: -266.309690019672
#> EM - StMoE: Iteration: 53 | log-likelihood: -266.176275700902
#> EM - StMoE: Iteration: 54 | log-likelihood: -266.058299377502
#> EM - StMoE: Iteration: 55 | log-likelihood: -265.954030565764
#> EM - StMoE: Iteration: 56 | log-likelihood: -265.861857108267
#> EM - StMoE: Iteration: 57 | log-likelihood: -265.780554931916
#> EM - StMoE: Iteration: 58 | log-likelihood: -265.708884053501
#> EM - StMoE: Iteration: 59 | log-likelihood: -265.645859773318
#> EM - StMoE: Iteration: 60 | log-likelihood: -265.590923652102
#> EM - StMoE: Iteration: 61 | log-likelihood: -265.543076918013
#> EM - StMoE: Iteration: 62 | log-likelihood: -265.501460541303
#> EM - StMoE: Iteration: 63 | log-likelihood: -265.465422522564
#> EM - StMoE: Iteration: 64 | log-likelihood: -265.434206715802
#> EM - StMoE: Iteration: 65 | log-likelihood: -265.407252143426
#> EM - StMoE: Iteration: 66 | log-likelihood: -265.384060024206
#> EM - StMoE: Iteration: 67 | log-likelihood: -265.364189492324
#> EM - StMoE: Iteration: 68 | log-likelihood: -265.34726752057
#> EM - StMoE: Iteration: 69 | log-likelihood: -265.333111496709
#> EM - StMoE: Iteration: 70 | log-likelihood: -265.321370917609
#> EM - StMoE: Iteration: 71 | log-likelihood: -265.311847233682
#> EM - StMoE: Iteration: 72 | log-likelihood: -265.304507732154
#> EM - StMoE: Iteration: 73 | log-likelihood: -265.298987571741
#> EM - StMoE: Iteration: 74 | log-likelihood: -265.295016966408
#> EM - StMoE: Iteration: 75 | log-likelihood: -265.292399201274

stmoe$plot()
```

<img src="man/figures/README-unnamed-chunk-6-1.png" style="display: block; margin: auto;" /><img src="man/figures/README-unnamed-chunk-6-2.png" style="display: block; margin: auto;" /><img src="man/figures/README-unnamed-chunk-6-3.png" style="display: block; margin: auto;" /><img src="man/figures/README-unnamed-chunk-6-4.png" style="display: block; margin: auto;" />

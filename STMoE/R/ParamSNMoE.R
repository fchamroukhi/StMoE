source("R/utils.R")
source("R/IRLS.R")

ParamSNMoE <- setRefClass(
  "ParamSNMoE",
  fields = list(
    alpha = "matrix",
    beta = "matrix",
    sigma = "matrix",
    lambda = "matrix",
    delta = "matrix"
  ),
  methods = list(
    initParam = function(modelSNMoE, phiAlpha, phiBeta, try_EM, segmental = FALSE) {
      alpha <<- matrix(runif((modelSNMoE$q + 1) * (modelSNMoE$K - 1)), nrow = modelSNMoE$q + 1, ncol = modelSNMoE$K - 1) #initialisation aléatoire du vercteur param�tre du IRLS

      #Initialise the regression parameters (coeffecients and variances):
      if (segmental == FALSE) {
        Zik <- zeros(modelSNMoE$n, modelSNMoE$K)

        klas <- floor(modelSNMoE$K * matrix(runif(modelSNMoE$n), modelSNMoE$n)) + 1

        Zik[klas %*% ones(1, modelSNMoE$K) == ones(modelSNMoE$n, 1) %*% seq(modelSNMoE$K)] <- 1

        Tauik <- Zik


        #beta <<- matrix(0, modelRHLP$p + 1, modelRHLP$K)
        #sigma <<- matrix(0, modelRHLP$K)

        for (k in 1:modelSNMoE$K) {
          Xk <- phiBeta$XBeta * (sqrt(Tauik[, k] %*% ones(1, modelSNMoE$p + 1)))
          yk <- modelSNMoE$Y * sqrt(Tauik[, k])

          beta[, k] <<- solve(t(Xk) %*% Xk) %*% t(Xk) %*% yk

          sigma[k] <<- sum(Tauik[, k] * ((modelSNMoE$Y - phiBeta$XBeta %*% beta[, k]) ^ 2)) / sum(Tauik[, k])
        }
      }
      else{
        #segmental : segment uniformly the data and estimate the parameters
        nk <- round(modelSNMoE$n / modelSNMoE$K) - 1

        for (k in 1:modelSNMoE$K) {
          i <- (k - 1) * nk + 1
          j <- (k * nk)
          yk <- matrix(modelSNMoE$Y[i:j])
          Xk <- phiBeta$XBeta[i:j,]

          beta[, k] <<- solve(t(Xk) %*% Xk) %*% (t(Xk) %*% yk)

          muk <- Xk %*% beta[, k]

          sigma[k] <<- t(yk - muk) %*% (yk - muk) / length(yk)
        }
      }

      if (try_EM == 1) {
        alpha <<- zeros(modelSNMoE$q + 1, modelSNMoE$K - 1)
      }

      # Initialize the skewness parameter Lambdak (by equivalence delta)
      delta <<- -1 + 2 * rand(1, modelSNMoE$K)

      lambda <<- delta / sqrt(1 - delta ^ 2)


    },

    MStep = function(modelSNMoE, statSNMoE, phiAlpha, phiBeta, verbose_IRLS) {
      # M-Step

      res_irls <- IRLS(tauijk = statSNMoE$tik, phiW = phiAlpha$XBeta, Wg_init = alpha, verbose_IRLS = verbose_IRLS)
      statSNMoE$piik <- res_irls$piik
      reg_irls <- res_irls$reg_irls

      alpha <<- res_irls$W

      for (k in 1:modelSNMoE$K) {
        #update the regression coefficients

        tauik_Xbeta <- (statSNMoE$tik[, k] %*% ones(1, modelSNMoE$p + 1)) * phiBeta$XBeta
        beta[, k] <<- solve((t(tauik_Xbeta) %*% phiAlpha$XBeta)) %*% (t(tauik_Xbeta) %*% (modelSNMoE$Y - delta[k] * statSNMoE$E1ik[, k]))

        # update the variances sigma2k

        sigma[k] <<- sum(statSNMoE$tik[, k] * ((modelSNMoE$Y - phiBeta$XBeta %*% beta[, k]) ^2 - 2 * delta[k] * statSNMoE$E1ik[, k] * (modelSNMoE$Y - phiBeta$XBeta %*% beta[, k]) + statSNMoE$E2ik[, k])) / (2 * (1 - delta[k] ^ 2) * sum(statSNMoE$tik[, k]))

        # update the deltak (the skewness parameter)
        delta[k] <<- uniroot(f <- function(dlt) {
          sigma[k] * dlt * (1 - dlt ^ 2) * sum(statSNMoE$tik[, k]) + (1 + dlt ^ 2) * sum(statSNMoE$tik[, k] * (modelSNMoE$Y -                                                                                                     phiBeta$XBeta %*% beta[, k]) * statSNMoE$E1ik[, k])
          - dlt * sum(statSNMoE$tik[, k] * (statSNMoE$E2ik[, k] + (modelSNMoE$Y - phiBeta$XBeta %*% beta[, k]) ^ 2))
        }, c(-1, 1))$root


        lambda[k] <<- delta[k] / sqrt(1 - delta[k] ^ 2)

      }

      return(reg_irls)
    }
  )
)

ParamSNMoE <- function(modelSNMoE) {
  alpha <- matrix(0, modelSNMoE$q + 1, modelSNMoE$K - 1)
  beta <- matrix(NA, modelSNMoE$p + 1, modelSNMoE$K)
  sigma <- matrix(NA, 1, modelSNMoE$K)
  lambda <- matrix(NA, modelSNMoE$K)
  delta <- matrix(NA, modelSNMoE$K)
  new("ParamSNMoE", alpha = alpha, beta = beta, sigma = sigma, lambda = lambda, delta = delta)
}

source("R/utils.R")
source("R/IRLS.R")

ParamSTMoE <- setRefClass(
  "ParamSTMoE",
  fields = list(
    alpha = "matrix",
    beta = "matrix",
    sigma = "matrix",
    lambda = "matrix",
    delta = "matrix",
    nuk = "matrix"
  ),
  methods = list(
    initParam = function(modelSTMoE, phiAlpha, phiBeta, try_EM, segmental = FALSE) {
      alpha <<- matrix(runif((modelSTMoE$q + 1) * (modelSTMoE$K - 1)), nrow = modelSTMoE$q + 1, ncol = modelSTMoE$K - 1) #initialisation aléatoire du vercteur param�tre du IRLS

      #Initialise the regression parameters (coeffecients and variances):
      if (segmental == FALSE) {
        Zik <- zeros(modelSTMoE$n, modelSTMoE$K)

        klas <- floor(modelSTMoE$K * matrix(runif(modelSTMoE$n), modelSTMoE$n)) + 1

        Zik[klas %*% ones(1, modelSTMoE$K) == ones(modelSTMoE$n, 1) %*% seq(modelSTMoE$K)] <- 1

        Tauik <- Zik


        #beta <<- matrix(0, modelRHLP$p + 1, modelRHLP$K)
        #sigma <<- matrix(0, modelRHLP$K)

        for (k in 1:modelSTMoE$K) {
          Xk <- phiBeta$XBeta * (sqrt(Tauik[, k] %*% ones(1, modelSTMoE$p + 1)))
          yk <- modelSTMoE$Y * sqrt(Tauik[, k])

          beta[, k] <<- solve(t(Xk) %*% Xk) %*% t(Xk) %*% yk

          sigma[k] <<- sum(Tauik[, k] * ((modelSTMoE$Y - phiBeta$XBeta %*% beta[, k]) ^ 2)) / sum(Tauik[, k])
        }
      }
      else{
        #segmental : segment uniformly the data and estimate the parameters
        nk <- round(modelSTMoE$n / modelSTMoE$K) - 1

        for (k in 1:modelSTMoE$K) {
          i <- (k - 1) * nk + 1
          j <- (k * nk)
          yk <- matrix(modelSTMoE$Y[i:j])
          Xk <- phiBeta$XBeta[i:j,]

          beta[, k] <<- solve(t(Xk) %*% Xk) %*% (t(Xk) %*% yk)

          muk <- Xk %*% beta[, k]

          sigma[k] <<- t(yk - muk) %*% (yk - muk) / length(yk)
        }
      }

      if (try_EM == 1) {
        alpha <<- zeros(modelSTMoE$q + 1, modelSTMoE$K - 1)
      }

      # Initialize the skewness parameter Lambdak (by equivalence delta)
      delta <<- -0.9 + 1.8 * rand(1, modelSTMoE$K)

      lambda <<- delta / sqrt(1 - delta ^ 2)

      # Intitialization of the degrees of freedm
      nuk <<- 1 + 5 * rand(1, modelSTMoE$K)
    },

    MStep = function(modelSTMoE, statSTMoE, phiAlpha, phiBeta, verbose_IRLS) {
      # M-Step

      res_irls <- IRLS(tauijk = statSTMoE$tik, phiW = phiAlpha$XBeta, Wg_init = alpha, verbose_IRLS = verbose_IRLS)
      statSTMoE$piik <- res_irls$piik
      reg_irls <- res_irls$reg_irls

      alpha <<- res_irls$W

      for (k in 1:modelSTMoE$K) {
        #update the regression coefficients
        TauikWik <- (statSTMoE$tik[,k] * statSTMoE$wik[,k]) %*% ones(1,modelSTMoE$p+1)
        TauikX <- phiBeta$XBeta * (statSTMoE$tik[,k] %*% ones(1, modelSTMoE$p+1))
        betak <- solve((t(TauikWik * phiBeta$XBeta) %*% phiAlpha$XBeta)) %*% (t(TauikX) %*% ( (statSTMoE$wik[,k] * modelSTMoE$Y) - (delta[k] * statSTMoE$E1ik[ ,k]) ))

        beta[,k] <<- betak;
        # update the variances sigma2k

        sigma[k] <<- sum(statSTMoE$tik[, k]*(statSTMoE$wik[,k] * ((modelSTMoE$Y-phiBeta$XBeta%*%betak)^2) - 2 * delta[k] * statSTMoE$E1ik[,k] * (modelSTMoE$Y - phiBeta$XBeta %*% betak) + statSTMoE$E2ik[,k]))/(2*(1-delta[k]^2) * sum(statSTMoE$tik[,k]))

        sigmak <- sqrt(sigma[k])

        # update the deltak (the skewness parameter)
        delta[k] <<- uniroot(f <- function(dlt) {
          dlt*(1-dlt^2)*sum(statSTMoE$tik[, k])
          + (1+ delta^2)*sum(statSTMoE$tik[, k] * statSTMoE$dik[,k]*statSTMoE$E1ik[,k]/sigmak)
          - dlt * sum(statSTMoE$tik[, k] * (statSTMoE$wik[,k] * (statSTMoE$dik[,k]^2) + statSTMoE$E2ik[,k]/(sigmak^2)))
        }, c(-1, 1))$root


        lambda[k] <<- delta[k] / sqrt(1 - delta[k] ^ 2)


        nuk[k] <<- uniroot(f <- function(nnu) {
          - psigamma((nnu)/2) + log((nnu)/2) + 1 + sum(statSTMoE$tik[,k] * (statSTMoE$E3ik[,k] - statSTMoE$wik[,k]))/sum(statSTMoE$tik[,k])
        }, c(0.1, 200))$root
      }

      return(reg_irls)
    }
  )
)

ParamSTMoE <- function(modelSTMoE) {
  alpha <- matrix(0, modelSTMoE$q + 1, modelSTMoE$K - 1)
  beta <- matrix(NA, modelSTMoE$p + 1, modelSTMoE$K)
  sigma <- matrix(NA, 1, modelSTMoE$K)
  lambda <- matrix(NA, modelSTMoE$K)
  delta <- matrix(NA, modelSTMoE$K)
  nuk <- matrix(NA, modelSTMoE$K)
  new("ParamSTMoE", alpha = alpha, beta = beta, sigma = sigma, lambda = lambda, delta = delta)
}

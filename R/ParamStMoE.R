ParamStMoE <- setRefClass(
  "ParamStMoE",
  fields = list(
    alpha = "matrix",
    beta = "matrix",
    sigma = "matrix",
    lambda = "matrix",
    delta = "matrix",
    nuk = "matrix"
  ),
  methods = list(
    initParam = function(modelStMoE, phiAlpha, phiBeta, try_EM, segmental = FALSE) {
      alpha <<- matrix(runif((modelStMoE$q + 1) * (modelStMoE$K - 1)), nrow = modelStMoE$q + 1, ncol = modelStMoE$K - 1) #initialisation al??atoire du vercteur param???tre du IRLS

      #Initialise the regression parameters (coeffecients and variances):
      if (segmental == FALSE) {
        Zik <- zeros(modelStMoE$n, modelStMoE$K)

        klas <- floor(modelStMoE$K * matrix(runif(modelStMoE$n), modelStMoE$n)) + 1

        Zik[klas %*% ones(1, modelStMoE$K) == ones(modelStMoE$n, 1) %*% seq(modelStMoE$K)] <- 1

        Tauik <- Zik


        #beta <<- matrix(0, modelRHLP$p + 1, modelRHLP$K)
        #sigma <<- matrix(0, modelRHLP$K)

        for (k in 1:modelStMoE$K) {
          Xk <- phiBeta$XBeta * (sqrt(Tauik[, k] %*% ones(1, modelStMoE$p + 1)))
          yk <- modelStMoE$Y * sqrt(Tauik[, k])

          beta[, k] <<- solve(t(Xk) %*% Xk) %*% t(Xk) %*% yk

          sigma[k] <<- sum(Tauik[, k] * ((modelStMoE$Y - phiBeta$XBeta %*% beta[, k]) ^ 2)) / sum(Tauik[, k])
        }
      }
      else{
        #segmental : segment uniformly the data and estimate the parameters
        nk <- round(modelStMoE$n / modelStMoE$K) - 1

        for (k in 1:modelStMoE$K) {
          i <- (k - 1) * nk + 1
          j <- (k * nk)
          yk <- matrix(modelStMoE$Y[i:j])
          Xk <- phiBeta$XBeta[i:j,]

          beta[, k] <<- solve(t(Xk) %*% Xk) %*% (t(Xk) %*% yk)

          muk <- Xk %*% beta[, k]

          sigma[k] <<- t(yk - muk) %*% (yk - muk) / length(yk)
        }
      }

      if (try_EM == 1) {
        alpha <<- rand(modelStMoE$q + 1, modelStMoE$K - 1)
      }

      # Initialize the skewness parameter Lambdak (by equivalence delta)
      delta <<- -0.9 + 1.8 * rand(1, modelStMoE$K)

      lambda <<- delta / sqrt(1 - delta ^ 2)

      # Intitialization of the degrees of freedm
      nuk <<- 1 + 5 * rand(1, modelStMoE$K)
    },

    MStep = function(modelStMoE, statStMoE, phiAlpha, phiBeta, verbose_IRLS) {
      # M-Step
      res_irls <- IRLS(phiAlpha$XBeta, statStMoE$tik, ones(nrow(statStMoE$tik), 1), alpha, verbose_IRLS)
      # statStMoE$piik <- res_irls$piik
      reg_irls <- res_irls$reg_irls

      alpha <<- res_irls$W

      for (k in 1:modelStMoE$K) {
        #update the regression coefficients
        TauikWik <- (statStMoE$tik[,k] * statStMoE$wik[,k]) %*% ones(1,modelStMoE$p+1)
        TauikX <- phiBeta$XBeta * (statStMoE$tik[,k] %*% ones(1, modelStMoE$p+1))
        betak <- solve((t(TauikWik * phiBeta$XBeta) %*% phiAlpha$XBeta)) %*% (t(TauikX) %*% ( (statStMoE$wik[,k] * modelStMoE$Y) - (delta[k] * statStMoE$E1ik[ ,k]) ))

        beta[,k] <<- betak;
        # update the variances sigma2k

        sigma[k] <<- sum(statStMoE$tik[, k]*(statStMoE$wik[,k] * ((modelStMoE$Y-phiBeta$XBeta%*%betak)^2) - 2 * delta[k] * statStMoE$E1ik[,k] * (modelStMoE$Y - phiBeta$XBeta %*% betak) + statStMoE$E2ik[,k]))/(2*(1-delta[k]^2) * sum(statStMoE$tik[,k]))

        sigmak <- sqrt(sigma[k])

        # update the deltak (the skewness parameter)
        delta[k] <<- uniroot(f <- function(dlt) {
          return(dlt*(1-dlt^2)*sum(statStMoE$tik[, k])
          + (1+ dlt^2)*sum(statStMoE$tik[, k] * statStMoE$dik[,k]*statStMoE$E1ik[,k]/sigmak)
          - dlt * sum(statStMoE$tik[, k] * (statStMoE$wik[,k] * (statStMoE$dik[,k]^2) + statStMoE$E2ik[,k]/(sigmak^2))))
        }, c(-1, 1))$root


        lambda[k] <<- delta[k] / sqrt(1 - delta[k] ^ 2)


        nuk[k] <<- uniroot(f <- function(nnu) {
          return(- psigamma((nnu)/2) + log((nnu)/2) + 1 + sum(statStMoE$tik[,k] * (statStMoE$E3ik[,k] - statStMoE$wik[,k]))/sum(statStMoE$tik[,k]))
        }, c(0.1, 200))$root
      }

      return(reg_irls)
    }
  )
)

ParamStMoE <- function(modelStMoE) {
  alpha <- matrix(0, modelStMoE$q + 1, modelStMoE$K - 1)
  beta <- matrix(NA, modelStMoE$p + 1, modelStMoE$K)
  sigma <- matrix(NA, 1, modelStMoE$K)
  lambda <- matrix(NA, modelStMoE$K)
  delta <- matrix(NA, modelStMoE$K)
  nuk <- matrix(NA, modelStMoE$K)
  new("ParamStMoE", alpha = alpha, beta = beta, sigma = sigma, lambda = lambda, delta = delta)
}

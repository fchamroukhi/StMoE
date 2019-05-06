source("R/model_logit.R")

StatSNMoE <- setRefClass(
  "StatSNMoE",
  fields = list(
    piik = "matrix",
    z_ik = "matrix",
    klas = "matrix",
    # Ex = "matrix",
    Ey_k = "matrix",
    Ey = "matrix",
    Var_yk = "matrix",
    Vary = "matrix",
    log_lik = "numeric",
    com_loglik = "numeric",
    stored_loglik = "list",
    BIC = "numeric",
    ICL = "numeric",
    AIC = "numeric",
    cpu_time = "numeric",
    log_piik_fik = "matrix",
    log_sum_piik_fik = "matrix",
    tik = "matrix",
    E1ik = "matrix",
    E2ik = "matrix"
  ),
  methods = list(
    MAP = function() {
      "
      calcule une partition d'un echantillon par la regle du Maximum A Posteriori à partir des probabilites a posteriori
      Entrees : post_probas , Matrice de dimensions [n x K] des probabibiltes a posteriori (matrice de la partition floue)
      n : taille de l'echantillon
      K : nombres de classes
      klas(i) = arg   max (post_probas(i,k)) , for all i=1,...,n
      1<=k<=K
      = arg   max  p(zi=k|xi;theta)
      1<=k<=K
      = arg   max  p(zi=k;theta)p(xi|zi=k;theta)/sum{l=1}^{K}p(zi=l;theta) p(xi|zi=l;theta)
      1<=k<=K
      Sorties : classes : vecteur collones contenant les classe (1:K)
      Z : Matrice de dimension [nxK] de la partition dure : ses elements sont zik, avec zik=1 si xi
      appartient à la classe k (au sens du MAP) et zero sinon.
      "
      N <- nrow(piik)
      K <- ncol(piik)
      ikmax <- max.col(piik)
      ikmax <- matrix(ikmax, ncol = 1)
      z_ik <<- ikmax %*% ones(1, K) == ones(N, 1) %*% (1:K) # partition_MAP
      klas <<- ones(N, 1)
      for (k in 1:K) {
        klas[z_ik[, k] == 1] <<- k
      }
    },
    #######
    # compute loglikelihood
    #######
    computeLikelihood = function(reg_irls) {
      log_lik <<- sum(log_sum_piik_fik) + reg_irls

    },
    #######
    #
    #######
    #######
    # compute the final solution stats
    #######
    computeStats = function(modelSNMoE, paramSNMoE, phiBeta, phiAlpha, cpu_time_all) {
      cpu_time <<- mean(cpu_time_all)

      # E[yi|zi=k]
      Ey_k <<- phiBeta$XBeta[1:modelSNMoE$n, ] %*% paramSNMoE$beta + ones(modelSNMoE$n, 1) %*% (sqrt(2 / pi) * paramSNMoE$delta * paramSNMoE$sigma)

      # E[yi]
      Ey <<- matrix(apply(piik * Ey_k, 1, sum))

      # Var[yi|zi=k]
      Var_yk <<- (1 - (2 / pi) * (paramSNMoE$delta ^ 2)) * (paramSNMoE$sigma ^ 2)

      # Var[yi]
      Vary <<- apply(piik * (Ey_k ^ 2 + ones(modelSNMoE$n, 1) %*% Var_yk), 1, sum) - Ey ^2


      ### BIC AIC et ICL

      BIC <<- log_lik - (modelSNMoE$nu * log(modelSNMoE$n * modelSNMoE$m) / 2)
      AIC <<- log_lik - modelSNMoE$nu
      ## CL(theta) : complete-data loglikelihood
      zik_log_piik_fk <- (repmat(z_ik, modelSNMoE$m, 1)) * log_piik_fik
      sum_zik_log_fik <- apply(zik_log_piik_fk, 1, sum)
      com_loglik <<- sum(sum_zik_log_fik)

      ICL <<- com_loglik - (modelSNMoE$nu * log(modelSNMoE$n * modelSNMoE$m) / 2)
      # solution.XBeta = XBeta(1:m,:);
      # solution.XAlpha = XAlpha(1:m,:);
    },
    #######
    # EStep
    #######
    EStep = function(modelSNMoE, paramSNMoE, phiBeta, phiAlpha) {
      piik <<- modele_logit(paramSNMoE$alpha, phiAlpha$XBeta)$probas

      piik_fik <- zeros(modelSNMoE$m * modelSNMoE$n, modelSNMoE$K)

      for (k in (1:modelSNMoE$K)) {
        muk <- phiBeta$XBeta %*% paramSNMoE$beta[, k]

        sigma2k <- paramSNMoE$sigma[k]
        sigmak <- sqrt(sigma2k)
        dik <- (modelSNMoE$Y - muk) / sigmak

        mu_uk <- (paramSNMoE$delta[k] * abs(modelSNMoE$Y - muk))
        sigma2_uk <- (1 - paramSNMoE$delta[k] ^ 2) * paramSNMoE$sigma[k]
        sigma_uk <- sqrt(sigma2_uk)

        E1ik[, k] <<- mu_uk + sigma_uk * dnorm(paramSNMoE$lambda[k] * dik, 0, 1) / pnorm(paramSNMoE$lambda[k] * dik, 0, 1)
        E2ik[, k] <<- mu_uk ^ 2 + sigma_uk ^ 2 + sigma_uk * mu_uk * dnorm(paramSNMoE$lambda[k] * dik, 0, 1) / pnorm(paramSNMoE$lambda[k] * dik, 0, 1)

        # weighted skew normal linear expert likelihood
        piik_fik[, k] <- piik[, k] * (2 / sigmak) * dnorm(dik, 0, 1) * pnorm(paramSNMoE$lambda[k] * dik)
      }

      log_piik_fik <<- log(piik_fik)

      log_sum_piik_fik <<- matrix(log(rowSums(piik_fik)))

      tik <<- piik_fik / (rowSums(piik_fik) %*% ones(1, modelSNMoE$K))
    }
  )
)


StatSNMoE <- function(modelSNMoE) {
  piik <- matrix(NA, modelSNMoE$n, modelSNMoE$K)
  z_ik <- matrix(NA, modelSNMoE$n, modelSNMoE$K)
  klas <- matrix(NA, modelSNMoE$n, 1)
  Ey_k <- matrix(NA, modelSNMoE$n, modelSNMoE$K)
  Ey <- matrix(NA, modelSNMoE$n, 1)
  Var_yk <- matrix(NA, 1, modelSNMoE$K)
  Vary <- matrix(NA, modelSNMoE$n, 1)
  log_lik <- -Inf
  com_loglik <- -Inf
  stored_loglik <- list()
  BIC <- -Inf
  ICL <- -Inf
  AIC <- -Inf
  cpu_time <- Inf
  log_piik_fik <- matrix(0, modelSNMoE$n, modelSNMoE$K)
  log_sum_piik_fik <- matrix(NA, modelSNMoE$n, 1)
  tik <- matrix(0, modelSNMoE$n, modelSNMoE$K)
  E1ik <- matrix(0, modelSNMoE$m * modelSNMoE$n, modelSNMoE$K)
  E2ik <- matrix(0, modelSNMoE$m * modelSNMoE$n, modelSNMoE$K)

  new(
    "StatSNMoE",
    piik = piik,
    z_ik = z_ik,
    klas = klas,
    Ey_k = Ey_k,
    Ey = Ey,
    Var_yk = Var_yk,
    Vary = Vary,
    log_lik = log_lik,
    com_loglik = com_loglik,
    stored_loglik = stored_loglik,
    BIC = BIC,
    ICL = ICL,
    AIC = AIC,
    cpu_time = cpu_time,
    log_piik_fik = log_piik_fik,
    log_sum_piik_fik = log_sum_piik_fik,
    tik = tik,
    E1ik = E1ik,
    E2ik = E2ik
  )
}

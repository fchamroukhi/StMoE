source("R/model_logit.R")

StatSTMoE <- setRefClass(
  "StatSTMoE",
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
    wik = "matrix",
    dik = "matrix",
    stme_pdf = "matrix",
    E1ik = "matrix",
    E2ik = "matrix",
    E3ik = "matrix"
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
    computeStats = function(modelSTMoE, paramSTMoE, phiBeta, phiAlpha, cpu_time_all) {
      cpu_time <<- mean(cpu_time_all)

      Xi_nuk = sqrt(paramSTMoE$nuk/pi) * (gamma(paramSTMoE$nuk/2 - 1/2)) / (gamma(paramSTMoE$nuk/2));

      # E[yi|zi=k]
      Ey_k <<- phiBeta$XBeta[1:modelSTMoE$n, ] %*% paramSTMoE$beta + ones(modelSTMoE$n, 1) %*% (paramSTMoE$delta * sqrt(paramSTMoE$sigma) * Xi_nuk)

      # E[yi]
      Ey <<- matrix(apply(piik * Ey_k, 1, sum))

      # Var[yi|zi=k]
      Var_yk <<- (paramSTMoE$nuk/(paramSTMoE$nuk-2) - (paramSTMoE$delta^2) * (Xi_nuk^2)) * paramSTMoE$sigma

      # Var[yi]
      Vary <<- apply(piik * (Ey_k ^ 2 + ones(modelSTMoE$n, 1) %*% Var_yk), 1, sum) - Ey ^2


      ### BIC AIC et ICL

      BIC <<- log_lik - (modelSTMoE$nu * log(modelSTMoE$n * modelSTMoE$m) / 2)
      AIC <<- log_lik - modelSTMoE$nu
      ## CL(theta) : complete-data loglikelihood
      zik_log_piik_fk <- (repmat(z_ik, modelSTMoE$m, 1)) * log_piik_fik
      sum_zik_log_fik <- apply(zik_log_piik_fk, 1, sum)
      com_loglik <<- sum(sum_zik_log_fik)

      ICL <<- com_loglik - (modelSTMoE$nu * log(modelSTMoE$n * modelSTMoE$m) / 2)
      # solution.XBeta = XBeta(1:m,:);
      # solution.XAlpha = XAlpha(1:m,:);
    },

    #######
    # Intial value for STMoE density
    #######
    univSTMoEpdf = function(modelSTMoE, paramSTMoE, phiBeta, phiAlpha){
      piik <<- modele_logit(paramSTMoE$alpha, phiAlpha$XBeta)$probas

      piik_fik <- zeros(modelSTMoE$n, modelSTMoE$K)
      dik <<- zeros(modelSTMoE$n, modelSTMoE$K)
      mik <- zeros(modelSTMoE$n, modelSTMoE$K)

      for (k in (1:modelSTMoE$K)){
        dik[,k] <<- (modelSTMoE$Y - phiBeta$XBeta %*% paramSTMoE$beta[, k])/ paramSTMoE$sigma[k]
        mik[,k] <- paramSTMoE$lambda[k] %*% dik[,k] * sqrt(paramSTMoE$nuk[k]+1)/(paramSTMoE$nuk[k] + dik[,k]^2)

        piik_fik[,k] <- piik[,k]*(2/paramSTMoE$sigma[k])*dt(dik[,k], paramSTMoE$nuk[k])*pt(mik[,k], paramSTMoE$nuk[k]+1)
      }

      stme_pdf <<- matrix(rowSums(piik_fik)) #  skew-t mixture of experts density
    },

    #######
    # EStep
    #######
    EStep = function(modelSTMoE, paramSTMoE, phiBeta, phiAlpha) {
      piik <<- modele_logit(paramSTMoE$alpha, phiAlpha$XBeta)$probas

      piik_fik <- zeros(modelSTMoE$m * modelSTMoE$n, modelSTMoE$K)

      dik <<- zeros(modelSTMoE$m * modelSTMoE$n, modelSTMoE$K)
      mik <- zeros(modelSTMoE$m * modelSTMoE$n, modelSTMoE$K)
      wik <<- zeros(modelSTMoE$m * modelSTMoE$n, modelSTMoE$K)


      for (k in (1:modelSTMoE$K)) {
        muk <- phiBeta$XBeta %*% paramSTMoE$beta[, k]

        sigma2k <- paramSTMoE$sigma[k]
        sigmak <- sqrt(sigma2k)
        dik[,k] <<- (modelSTMoE$Y - muk) / sigmak

        mik[,k] <- paramSTMoE$lambda[k] %*% dik[,k] * sqrt((paramSTMoE$nuk[k] +1)/(paramSTMoE$nuk[k] + dik[,k]^2))

        # E[Wi|yi,zik=1]
        wik[,k] <<- ((paramSTMoE$nuk[k] + 1)/(paramSTMoE$nuk[k] + dik[,k]^2)) * pt(mik[,k]*sqrt((paramSTMoE$nuk[k] + 3)/(paramSTMoE$nuk[k] + 1)), paramSTMoE$nuk[k] + 3)/pt(mik[,k], paramSTMoE$nuk[k] + 1)

        # E[Wi Ui |yi,zik=1]
        deltak <- paramSTMoE$delta[k]

        E1ik[, k] <<- deltak * abs(modelSTMoE$Y - muk) * wik[,k] + (sqrt(1 - deltak^2)/(pi * stme_pdf)) * ((dik[,k]^2/(paramSTMoE$nuk[k]*(1 - deltak^2)) + 1)^(-(paramSTMoE$nuk[k]/2 + 1)))
        E2ik[, k] <<- deltak^2 * ((modelSTMoE$Y - muk)^2) * wik[,k] + (1 - deltak^2) * sigmak^2 + ((deltak * (modelSTMoE$Y - muk) * sqrt(1 - deltak^2))/(pi * stme_pdf)) * (((dik[,k]^2)/(paramSTMoE$nuk[k] * (1 - deltak^2)) + 1)^(-(paramSTMoE$nuk[k]/2 + 1)))

        Integgtx <- 0
        E3ik[, k] <<- wik[,k] - log((paramSTMoE$nuk[k] + dik[,k]^2)/2) -(paramSTMoE$nuk[k] + 1)/(paramSTMoE$nuk[k] + dik[,k]^2) + psigamma((paramSTMoE$nuk[k] + 1)/2) + ((paramSTMoE$lambda[k] * dik[,k] * (dik[,k]^2 - 1)) / sqrt((paramSTMoE$nuk[k] + 1)*((paramSTMoE$nuk[k] + dik[,k]^2)^3))) * dt(mik[,k], paramSTMoE$nuk[k]+1) / pt(mik[,k], paramSTMoE$nuk[k] + 1) + (1./pt(mik[,k], paramSTMoE$nuk[k] + 1)) * Integgtx;

        # weighted skew normal linear expert likelihood
        piik_fik[, k] <- piik[, k] * (2 / sigmak) * dt(dik[, k], paramSTMoE$nuk[k]) * pt(mik[,k], paramSTMoE$nuk[k] + 1);
      }


      stme_pdf <<- matrix(rowSums(piik_fik)) # skew-t mixture of experts density

      log_piik_fik <<- log(piik_fik)

      log_sum_piik_fik <<- matrix(log(rowSums(piik_fik)))

      #E[Zi=k|yi]
      tik <<- piik_fik / (stme_pdf %*% ones(1,modelSTMoE$K))
    }
  )
)


StatSTMoE <- function(modelSTMoE) {
  piik <- matrix(NA, modelSTMoE$n, modelSTMoE$K)
  z_ik <- matrix(NA, modelSTMoE$n, modelSTMoE$K)
  klas <- matrix(NA, modelSTMoE$n, 1)
  Ey_k <- matrix(NA, modelSTMoE$n, modelSTMoE$K)
  Ey <- matrix(NA, modelSTMoE$n, 1)
  Var_yk <- matrix(NA, 1, modelSTMoE$K)
  Vary <- matrix(NA, modelSTMoE$n, 1)
  log_lik <- -Inf
  com_loglik <- -Inf
  stored_loglik <- list()
  BIC <- -Inf
  ICL <- -Inf
  AIC <- -Inf
  cpu_time <- Inf
  log_piik_fik <- matrix(0, modelSTMoE$n, modelSTMoE$K)
  log_sum_piik_fik <- matrix(NA, modelSTMoE$n, 1)
  tik <- matrix(0, modelSTMoE$n, modelSTMoE$K)
  wik <- matrix(0, modelSTMoE$m * modelSTMoE$n, modelSTMoE$K)
  dik <- matrix(0, modelSTMoE$m * modelSTMoE$n, modelSTMoE$K)
  stme_pdf <- matrix(0, modelSTMoE$n, 1)
  E1ik <- matrix(0, modelSTMoE$m * modelSTMoE$n, modelSTMoE$K)
  E2ik <- matrix(0, modelSTMoE$m * modelSTMoE$n, modelSTMoE$K)
  E3ik <- matrix(0, modelSTMoE$m * modelSTMoE$n, modelSTMoE$K)

  new(
    "StatSTMoE",
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
    wik = wik,
    dik = dik,
    stme_pdf = stme_pdf,
    E1ik = E1ik,
    E2ik = E2ik,
    E3ik = E3ik
  )
}

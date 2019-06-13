#' @export
StatStMoE <- setRefClass(
  "StatStMoE",
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
    initialize = function(paramStMoE = ParamStMoE(fData = FData(numeric(1), matrix(1)), K = 1, p = 2, q = 1)) {
      piik <<- matrix(NA, paramStMoE$fData$n, paramStMoE$K)
      z_ik <<- matrix(NA, paramStMoE$fData$n, paramStMoE$K)
      klas <<- matrix(NA, paramStMoE$fData$n, 1)
      Ey_k <<- matrix(NA, paramStMoE$fData$n, paramStMoE$K)
      Ey <<- matrix(NA, paramStMoE$fData$n, 1)
      Var_yk <<- matrix(NA, 1, paramStMoE$K)
      Vary <<- matrix(NA, paramStMoE$fData$n, 1)
      log_lik <<- -Inf
      com_loglik <<- -Inf
      stored_loglik <<- list()
      BIC <<- -Inf
      ICL <<- -Inf
      AIC <<- -Inf
      cpu_time <<- Inf
      log_piik_fik <<- matrix(0, paramStMoE$fData$n, paramStMoE$K)
      log_sum_piik_fik <<- matrix(NA, paramStMoE$fData$n, 1)
      tik <<- matrix(0, paramStMoE$fData$n, paramStMoE$K)
      wik <<- matrix(0, paramStMoE$fData$m * paramStMoE$fData$n, paramStMoE$K)
      dik <<- matrix(0, paramStMoE$fData$m * paramStMoE$fData$n, paramStMoE$K)
      stme_pdf <<- matrix(0, paramStMoE$fData$n, 1)
      E1ik <<- matrix(0, paramStMoE$fData$m * paramStMoE$fData$n, paramStMoE$K)
      E2ik <<- matrix(0, paramStMoE$fData$m * paramStMoE$fData$n, paramStMoE$K)
      E3ik <<- matrix(0, paramStMoE$fData$m * paramStMoE$fData$n, paramStMoE$K)
    },

    MAP = function() {
      "
      calcule une partition d'un echantillon par la regle du Maximum A Posteriori ?? partir des probabilites a posteriori
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
      appartient ?? la classe k (au sens du MAP) et zero sinon.
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
    computeStats = function(paramStMoE, cpu_time_all) {
      cpu_time <<- mean(cpu_time_all)

      Xi_nuk = sqrt(paramStMoE$nuk/pi) * (gamma(paramStMoE$nuk/2 - 1/2)) / (gamma(paramStMoE$nuk/2));

      # E[yi|zi=k]
      Ey_k <<- paramStMoE$phiBeta$XBeta[1:paramStMoE$fData$n, ] %*% paramStMoE$beta + ones(paramStMoE$fData$n, 1) %*% (paramStMoE$delta * sqrt(paramStMoE$sigma) * Xi_nuk)

      # E[yi]
      Ey <<- matrix(apply(piik * Ey_k, 1, sum))

      # Var[yi|zi=k]
      Var_yk <<- (paramStMoE$nuk/(paramStMoE$nuk-2) - (paramStMoE$delta^2) * (Xi_nuk^2)) * paramStMoE$sigma

      # Var[yi]
      Vary <<- apply(piik * (Ey_k ^ 2 + ones(paramStMoE$fData$n, 1) %*% Var_yk), 1, sum) - Ey ^2


      ### BIC AIC et ICL

      BIC <<- log_lik - (paramStMoE$nu * log(paramStMoE$fData$n * paramStMoE$fData$m) / 2)
      AIC <<- log_lik - paramStMoE$nu
      ## CL(theta) : complete-data loglikelihood
      zik_log_piik_fk <- (repmat(z_ik, paramStMoE$fData$m, 1)) * log_piik_fik
      sum_zik_log_fik <- apply(zik_log_piik_fk, 1, sum)
      com_loglik <<- sum(sum_zik_log_fik)

      ICL <<- com_loglik - (paramStMoE$nu * log(paramStMoE$fData$n * paramStMoE$fData$m) / 2)
      # solution.XBeta = XBeta(1:m,:);
      # solution.XAlpha = XAlpha(1:m,:);
    },

    #######
    # Intial value for STMoE density
    #######
    univStMoEpdf = function(paramStMoE){
      piik <<- multinomialLogit(paramStMoE$alpha, paramStMoE$phiAlpha$XBeta, ones(paramStMoE$fData$n, paramStMoE$K), ones(paramStMoE$fData$n, 1))$piik

      piik_fik <- zeros(paramStMoE$fData$n, paramStMoE$K)
      dik <<- zeros(paramStMoE$fData$n, paramStMoE$K)
      mik <- zeros(paramStMoE$fData$n, paramStMoE$K)

      for (k in (1:paramStMoE$K)){
        dik[,k] <<- (paramStMoE$fData$Y - paramStMoE$phiBeta$XBeta %*% paramStMoE$beta[, k])/ paramStMoE$sigma[k]
        mik[,k] <- paramStMoE$lambda[k] %*% dik[,k] * sqrt(paramStMoE$nuk[k]+1)/(paramStMoE$nuk[k] + dik[,k]^2)

        piik_fik[,k] <- piik[,k]*(2/paramStMoE$sigma[k])*dt(dik[,k], paramStMoE$nuk[k])*pt(mik[,k], paramStMoE$nuk[k]+1)
      }

      stme_pdf <<- matrix(rowSums(piik_fik)) #  skew-t mixture of experts density
    },

    #######
    # EStep
    #######
    EStep = function(paramStMoE) {
      piik <<- multinomialLogit(paramStMoE$alpha, paramStMoE$phiAlpha$XBeta, ones(paramStMoE$fData$n, paramStMoE$K), ones(paramStMoE$fData$n, 1))$piik

      piik_fik <- zeros(paramStMoE$fData$m * paramStMoE$fData$n, paramStMoE$K)

      dik <<- zeros(paramStMoE$fData$m * paramStMoE$fData$n, paramStMoE$K)
      mik <- zeros(paramStMoE$fData$m * paramStMoE$fData$n, paramStMoE$K)
      wik <<- zeros(paramStMoE$fData$m * paramStMoE$fData$n, paramStMoE$K)


      for (k in (1:paramStMoE$K)) {
        muk <- paramStMoE$phiBeta$XBeta %*% paramStMoE$beta[, k]

        sigma2k <- paramStMoE$sigma[k]
        sigmak <- sqrt(sigma2k)
        dik[,k] <<- (paramStMoE$fData$Y - muk) / sigmak

        mik[,k] <- paramStMoE$lambda[k] %*% dik[,k] * sqrt((paramStMoE$nuk[k] +1)/(paramStMoE$nuk[k] + dik[,k]^2))

        # E[Wi|yi,zik=1]
        wik[,k] <<- ((paramStMoE$nuk[k] + 1)/(paramStMoE$nuk[k] + dik[,k]^2)) * pt(mik[,k]*sqrt((paramStMoE$nuk[k] + 3)/(paramStMoE$nuk[k] + 1)), paramStMoE$nuk[k] + 3)/pt(mik[,k], paramStMoE$nuk[k] + 1)

        # E[Wi Ui |yi,zik=1]
        deltak <- paramStMoE$delta[k]

        E1ik[, k] <<- deltak * abs(paramStMoE$fData$Y - muk) * wik[,k] + (sqrt(1 - deltak^2)/(pi * stme_pdf)) * ((dik[,k]^2/(paramStMoE$nuk[k]*(1 - deltak^2)) + 1)^(-(paramStMoE$nuk[k]/2 + 1)))
        E2ik[, k] <<- deltak^2 * ((paramStMoE$fData$Y - muk)^2) * wik[,k] + (1 - deltak^2) * sigmak^2 + ((deltak * (paramStMoE$fData$Y - muk) * sqrt(1 - deltak^2))/(pi * stme_pdf)) * (((dik[,k]^2)/(paramStMoE$nuk[k] * (1 - deltak^2)) + 1)^(-(paramStMoE$nuk[k]/2 + 1)))

        Integgtx <- 0
        E3ik[, k] <<- wik[,k] - log((paramStMoE$nuk[k] + dik[,k]^2)/2) -(paramStMoE$nuk[k] + 1)/(paramStMoE$nuk[k] + dik[,k]^2) + psigamma((paramStMoE$nuk[k] + 1)/2) + ((paramStMoE$lambda[k] * dik[,k] * (dik[,k]^2 - 1)) / sqrt((paramStMoE$nuk[k] + 1)*((paramStMoE$nuk[k] + dik[,k]^2)^3))) * dt(mik[,k], paramStMoE$nuk[k]+1) / pt(mik[,k], paramStMoE$nuk[k] + 1) + (1./pt(mik[,k], paramStMoE$nuk[k] + 1)) * Integgtx;

        # weighted skew normal linear expert likelihood
        piik_fik[, k] <- piik[, k] * (2 / sigmak) * dt(dik[, k], paramStMoE$nuk[k]) * pt(mik[,k], paramStMoE$nuk[k] + 1);
      }


      stme_pdf <<- matrix(rowSums(piik_fik)) # skew-t mixture of experts density

      log_piik_fik <<- log(piik_fik)

      log_sum_piik_fik <<- matrix(log(rowSums(piik_fik)))

      #E[Zi=k|yi]
      tik <<- piik_fik / (stme_pdf %*% ones(1,paramStMoE$K))
    }
  )
)

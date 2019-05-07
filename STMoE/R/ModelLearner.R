source("R/utils.R")
source("R/ParamSTMoE.R")
source("R/StatSTMoE.R")
# source("R/FittedSTMoE.R")

EM <- function(modelSTMoE, n_tries = 1, max_iter = 1500, threshold = 1e-6, verbose = FALSE, verbose_IRLS = FALSE) {
    phiBeta <- designmatrix(x = modelSTMoE$X, p = modelSTMoE$p)
    phiAlpha <- designmatrix(x = modelSTMoE$X, p = modelSTMoE$q)

    top <- 0
    try_EM <- 0
    best_loglik <- -Inf
    cpu_time_all <- c()

    while (try_EM < n_tries) {
      try_EM <- try_EM + 1
      message("EM try nr ", try_EM)
      time <- Sys.time()

      # Initializations
      param <- ParamSTMoE(modelSTMoE)
      param$initParam(modelSTMoE, phiAlpha, phiBeta, try_EM, segmental = TRUE)



      iter <- 0
      converge <- FALSE
      prev_loglik <- -Inf

      stat <- StatSTMoE(modelSTMoE)
      stat$univSTMoEpdf(modelSTMoE, param, phiBeta, phiAlpha)

      while (!converge && (iter <= max_iter)) {
        stat$EStep(modelSTMoE, param, phiBeta, phiAlpha)

        reg_irls <- param$MStep(modelSTMoE, stat, phiAlpha, phiBeta, verbose_IRLS)

        stat$computeLikelihood(reg_irls)
        # FIN EM

        iter <- iter + 1
        if (verbose) {
          message("EM : Iteration : ", iter," log-likelihood : "  , stat$log_lik)
        }
        if (prev_loglik - stat$log_lik > 1e-5) {
          message("!!!!! EM log-likelihood is decreasing from ", prev_loglik, "to ", stat$log_lik)
          top <- top + 1
          if (top > 20)
            break
        }

        # TEST OF CONVERGENCE
        converge <- abs((stat$log_lik - prev_loglik) / prev_loglik) <= threshold
        if (is.na(converge)) {
          converge <- FALSE
        } # Basically for the first iteration when prev_loglik is Inf

        prev_loglik <- stat$log_lik
        stat$stored_loglik[iter] <- stat$log_lik
      }# FIN EM LOOP


      cpu_time_all[try_EM] <- Sys.time() - time

      # at this point we have computed param and stat that contains all the information

      if (stat$log_lik > best_loglik) {
        statSolution <- stat$copy()
        paramSolution <- param$copy()

        best_loglik <- stat$log_lik
      }
      if (n_tries > 1) {
        message("max value: ", stat$log_lik)
      }
    }

    # Computation of c_ig the hard partition of the curves and klas
    statSolution$MAP()

    if (n_tries > 1) {
      message("max value: ", statSolution$log_lik)
    }


    # FINISH computation of statSolution
    statSolution$computeStats(modelSTMoE, paramSolution, phiBeta, phiAlpha, cpu_time_all)

    return(FittedSTMoE(modelSTMoE, paramSolution, statSolution))

  }

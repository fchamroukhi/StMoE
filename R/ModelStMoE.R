#' @export
ModelStMoE <- setRefClass(
  "ModelStMoE",
  fields = list(
    paramStMoE = "ParamStMoE",
    statStMoE = "StatStMoE"
  ),
  methods = list(
    plot = function() {

      plot.default(paramStMoE$fData$X, paramStMoE$fData$Y, ylab = "y", xlab = "x", cex = 0.7, pch = 3)
      title(main = "Estimated mean and experts")
      for (k in 1:paramStMoE$K) {
        lines(paramStMoE$fData$X, statStMoE$Ey_k[, k], col = "red", lty = "dotted", lwd = 1.5)
      }
      lines(paramStMoE$fData$X, statStMoE$Ey, col = "red", lwd = 1.5)


      colorsvec = rainbow(paramStMoE$K)
      plot.default(paramStMoE$fData$X, statStMoE$piik[, 1], type = "l", xlab = "x", ylab = "Mixing probabilities", col = colorsvec[1])
      title(main = "Mixing probabilities")
      for (k in 2:paramStMoE$K) {
        lines(paramStMoE$fData$X, statStMoE$piik[, k], col = colorsvec[k])
      }

      # Data, Estimated mean functions and 2*sigma confidence regions
      plot.default(paramStMoE$fData$X, paramStMoE$fData$Y, ylab = "y", xlab = "x", cex = 0.7, pch = 3)
      title(main = "Estimated mean and confidence regions")
      lines(paramStMoE$fData$X, statStMoE$Ey, col = "red", lwd = 1.5)
      lines(paramStMoE$fData$X, statStMoE$Ey - 2 * sqrt(statStMoE$Vary), col = "red", lty = "dotted", lwd = 1.5)
      lines(paramStMoE$fData$X, statStMoE$Ey + 2 * sqrt(statStMoE$Vary), col = "red", lty = "dotted", lwd = 1.5)

      # Obtained partition
      plot.default(paramStMoE$fData$X, paramStMoE$fData$Y, ylab = "y", xlab = "x", cex = 0.7, pch = 3)
      title(main = "Estimated experts and clusters")
      for (k in 1:paramStMoE$K) {
        lines(paramStMoE$fData$X, statStMoE$Ey_k[, k], col = colorsvec[k], lty = "dotted", lwd = 1.5)
      }
      for (k in 1:paramStMoE$K) {
        index <- statStMoE$klas == k
        points(paramStMoE$fData$X[index], paramStMoE$fData$Y[index, ], col = colorsvec[k], cex = 0.7, pch = 3)
      }

      # Observed data log-likelihood
      plot.default(unlist(statStMoE$stored_loglik), type = "l", col = "blue", xlab = "EM iteration number", ylab = "Observed data log-likelihood")
      title(main = "Log-Likelihood")

    }
  )
)

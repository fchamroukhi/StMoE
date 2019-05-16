FittedSTMoE <- setRefClass(
  "FittedSTMoE",
  fields = list(
    modelSTMoE = "ModelSTMoE",
    paramSTMoE = "ParamSTMoE",
    statSTMoE = "StatSTMoE"
  ),
  methods = list(
    plot = function() {

      plot.default(modelSTMoE$X, modelSTMoE$Y, ylab = "y", xlab = "x", cex = 0.7, pch = 3)
      title(main = "Estimated mean and experts")
      for (k in 1:modelSTMoE$K) {
        lines(modelSTMoE$X, statSTMoE$Ey_k[, k], col = "red", lty = "dotted", lwd = 1.5)
      }
      lines(modelSTMoE$X, statSTMoE$Ey, col = "red", lwd = 1.5)


      colorsvec = rainbow(modelSTMoE$K)
      plot.default(modelSTMoE$X, statSTMoE$piik[, 1], type = "l", xlab = "x", ylab = "Mixing probabilities", col = colorsvec[1])
      title(main = "Mixing probabilities")
      for (k in 2:modelSTMoE$K) {
        lines(modelSTMoE$X, statSTMoE$piik[, k], col = colorsvec[k])
      }

      # Data, Estimated mean functions and 2*sigma confidence regions
      plot.default(modelSTMoE$X, modelSTMoE$Y, ylab = "y", xlab = "x", cex = 0.7, pch = 3)
      title(main = "Estimated mean and confidence regions")
      lines(modelSTMoE$X, statSTMoE$Ey, col = "red", lwd = 1.5)
      lines(modelSTMoE$X, statSTMoE$Ey - 2 * sqrt(statSTMoE$Vary), col = "red", lty = "dotted", lwd = 1.5)
      lines(modelSTMoE$X, statSTMoE$Ey + 2 * sqrt(statSTMoE$Vary), col = "red", lty = "dotted", lwd = 1.5)

      # Obtained partition
      plot.default(modelSTMoE$X, modelSTMoE$Y, ylab = "y", xlab = "x", cex = 0.7, pch = 3)
      title(main = "Estimated experts and clusters")
      for (k in 1:modelSTMoE$K) {
        lines(modelSTMoE$X, statSTMoE$Ey_k[, k], col = colorsvec[k], lty = "dotted", lwd = 1.5)
      }
      for (k in 1:modelSTMoE$K) {
        index <- statSTMoE$klas == k
        points(modelSTMoE$X[, index], modelSTMoE$Y[index, ], col = colorsvec[k], cex = 0.7, pch = 3)
      }

      # Observed data log-likelihood
      plot.default(unlist(statSTMoE$stored_loglik), type = "l", col = "blue", xlab = "EM iteration number", ylab = "Observed data log-likelihood")
      title(main = "Log-Likelihood")

    }
  )
)

FittedSTMoE <- function(modelSTMoE, paramSTMoE, statSTMoE) {
  new("FittedSTMoE", modelSTMoE = modelSTMoE, paramSTMoE = paramSTMoE, statSTMoE = statSTMoE)
}

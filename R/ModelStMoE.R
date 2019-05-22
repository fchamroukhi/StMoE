ModelStMoE <- setRefClass(
  "ModelStMoE",
  contains = "FData",
  # Define the fields
  fields = list(
    K = "numeric",
    # number of regimes
    p = "numeric",
    # dimension of beta (order of polynomial regression)
    q = "numeric",
    # dimension of w (order of logistic regression)
    nu = "numeric" # degree of freedom
  )
)

ModelStMoE <- function(fData, K, p, q) {
  nu <<- (p + q + 3) * K - (q + 1)

  new(
    "ModelStMoE",
    Y = fData$Y,
    X = fData$X,
    m = fData$m,
    n = fData$n,
    K = K,
    p = p,
    q = q,
    nu = nu
  )
}

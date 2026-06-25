#include "Package.h"
#include "OptimizationProblem.h"

#include <algorithm> // std::fill
#include <cmath>     // std::isfinite

// [[Rcpp::export]]
Rcpp::List rcpp_reset_objective(SEXP x, std::string modelsense = "") {
  Rcpp::XPtr<OptimizationProblem> op = Rcpp::as<Rcpp::XPtr<OptimizationProblem>>(x);

  if (!modelsense.empty()) {
    if (modelsense != "min" && modelsense != "max") Rcpp::stop("modelsense must be 'min' or 'max'.");
    op->_modelsense = modelsense;
  }

  std::fill(op->_obj.begin(), op->_obj.end(), 0.0);


  return Rcpp::List::create(Rcpp::Named("ok") = true);
}

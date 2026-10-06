#include "Package.h"
#include "OptimizationProblem.h"
#include <cmath>
#include <set>

// Exact positive part of a signed linear expression. These constraints remain
// exact when loss is a secondary objective, has zero weight, or is evaluated
// during payoff/lexicographic solves.
// [[Rcpp::export]]
Rcpp::List rcpp_add_effect_loss_variables(SEXP model_ptr, Rcpp::List columns0,
                                         Rcpp::List coefficients) {
  if (Rf_isNull(model_ptr)) Rcpp::stop("model_ptr is NULL.");
  Rcpp::XPtr<OptimizationProblem> op(model_ptr);
  if (columns0.size() != coefficients.size()) Rcpp::stop("Loss expression lengths differ.");
  std::vector<std::vector<int>> columns;
  std::vector<std::vector<double>> values;
  std::vector<double> lower, upper;
  const size_t original_ncol = op->ncol_used();
  // Validate everything before changing the model.
  for (int k = 0; k < columns0.size(); ++k) {
    Rcpp::IntegerVector cols = columns0[k];
    Rcpp::NumericVector coefs = coefficients[k];
    if (cols.size() == 0 || cols.size() != coefs.size()) Rcpp::stop("Invalid loss expression lengths.");
    std::set<int> seen;
    double lo = 0.0, hi = 0.0;
    for (int j = 0; j < cols.size(); ++j) {
      if (cols[j] == NA_INTEGER || cols[j] < 0 || static_cast<size_t>(cols[j]) >= original_ncol ||
          !seen.insert(cols[j]).second) Rcpp::stop("Invalid or duplicated loss expression column.");
      if (!std::isfinite(coefs[j])) Rcpp::stop("Loss coefficients must be finite.");
      if (op->_lb[cols[j]] < 0.0 || op->_ub[cols[j]] > 1.0)
        Rcpp::stop("Loss expression variables must be bounded between zero and one.");
      lo += std::min(0.0, coefs[j]);
      hi += std::max(0.0, coefs[j]);
    }
    if (!std::isfinite(lo) || !std::isfinite(hi) || !(lo < 0.0 && hi > 0.0))
      Rcpp::stop("Loss linearization requires finite mixed-sign bounds.");
    columns.emplace_back(cols.begin(), cols.end());
    values.emplace_back(coefs.begin(), coefs.end());
    lower.push_back(lo);
    upper.push_back(hi);
  }
  const size_t start = op->ncol_used(), row_start = op->nrow_used();
  Rcpp::IntegerVector loss_columns(columns.size()), sign_columns(columns.size());
  for (size_t k = 0; k < columns.size(); ++k) {
    loss_columns[k] = op->ncol_used();
    op->_obj.push_back(0.0); op->_vtype.push_back("C");
    op->_lb.push_back(0.0); op->_ub.push_back(-lower[k]);
    sign_columns[k] = op->ncol_used();
    op->_obj.push_back(0.0); op->_vtype.push_back("B");
    op->_lb.push_back(0.0); op->_ub.push_back(1.0);
  }
  if (!columns.empty()) {
    op->register_variable_block("effect_losses", start, op->ncol_used(), "exact_final_loss");
    const size_t block = op->beginConstraintBlock("effect_losses", "exact_final_loss");
    for (size_t k = 0; k < columns.size(); ++k) {
      auto cols = columns[k];
      auto coefs = values[k];
      cols.push_back(loss_columns[k]); coefs.push_back(1.0);
      // loss + delta >= 0
      op->addRow(cols, coefs, ">=", 0.0, "loss_lower_" + std::to_string(k));
      // loss + delta + U*sign <= U
      cols.push_back(sign_columns[k]); coefs.push_back(upper[k]);
      op->addRow(cols, coefs, "<=", upper[k], "loss_upper_" + std::to_string(k));
      // loss <= -L*sign
      op->addRow({loss_columns[k], sign_columns[k]}, {1.0, lower[k]}, "<=", 0.0,
                 "loss_sign_" + std::to_string(k));
    }
    op->endConstraintBlock(block);
  }
  return Rcpp::List::create(Rcpp::Named("columns0") = loss_columns,
                           Rcpp::Named("sign_columns0") = sign_columns,
                           Rcpp::Named("n_variables") = op->ncol_used() - start,
                           Rcpp::Named("n_constraints") = op->nrow_used() - row_start);
}

// Exact OR for action-scoped reference contributions in ecological targets.
// [[Rcpp::export]]
Rcpp::List rcpp_add_effect_selection_variables(SEXP model_ptr, Rcpp::List members0) {
  if (Rf_isNull(model_ptr)) Rcpp::stop("model_ptr is NULL.");
  Rcpp::XPtr<OptimizationProblem> op(model_ptr);
  std::vector<std::vector<int>> groups;
  for (int k = 0; k < members0.size(); ++k) {
    Rcpp::IntegerVector members = members0[k];
    std::set<int> seen;
    if (members.size() < 2) Rcpp::stop("Selection OR requires at least two members.");
    for (int col : members) {
      if (col == NA_INTEGER || col < op->_x_offset || col >= op->_x_offset + op->_n_x ||
          !seen.insert(col).second) Rcpp::stop("Invalid or duplicated selection member column.");
    }
    groups.emplace_back(members.begin(), members.end());
  }
  const size_t start = op->ncol_used(), row_start = op->nrow_used();
  Rcpp::IntegerVector result(groups.size());
  for (size_t k = 0; k < groups.size(); ++k) {
    result[k] = op->ncol_used();
    op->_obj.push_back(0.0); op->_vtype.push_back("C");
    op->_lb.push_back(0.0); op->_ub.push_back(1.0);
  }
  if (!groups.empty()) {
    op->register_variable_block("effect_selection", start, op->ncol_used(), "exact_OR");
    const size_t block = op->beginConstraintBlock("effect_selection", "exact_OR");
    for (size_t k = 0; k < groups.size(); ++k) {
      for (int col : groups[k])
        op->addRow({result[k], col}, {1.0, -1.0}, ">=", 0.0,
                   "effect_selection_lower_" + std::to_string(k) + "_" + std::to_string(col));
      auto cols = groups[k];
      std::vector<double> coefs(cols.size(), -1.0);
      cols.push_back(result[k]); coefs.push_back(1.0);
      op->addRow(cols, coefs, "<=", 0.0, "effect_selection_upper_" + std::to_string(k));
    }
    op->endConstraintBlock(block);
  }
  return Rcpp::List::create(Rcpp::Named("columns0") = result,
                           Rcpp::Named("n_variables") = op->ncol_used() - start,
                           Rcpp::Named("n_constraints") = op->nrow_used() - row_start);
}

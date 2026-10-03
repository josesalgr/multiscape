#include "Package.h"
#include "OptimizationProblem.h"
#include <set>

// Exact AND with continuous auxiliaries. Validate the entire input before mutation.
// [[Rcpp::export]]
Rcpp::List rcpp_add_joint_effect_variables(SEXP model_ptr, Rcpp::List members0) {
  if (Rf_isNull(model_ptr)) Rcpp::stop("model_ptr is NULL.");
  Rcpp::XPtr<OptimizationProblem> op(model_ptr);
  std::vector<std::vector<int>> groups;
  for (int k = 0; k < members0.size(); ++k) {
    Rcpp::IntegerVector members = Rcpp::as<Rcpp::IntegerVector>(members0[k]);
    std::set<int> unique;
    if (members.size() < 2) Rcpp::stop("Joint activation requires at least two members.");
    for (int col : members) {
      if (col == NA_INTEGER || col < op->_x_offset || col >= op->_x_offset + op->_n_x ||
          !unique.insert(col).second) Rcpp::stop("Invalid or duplicated joint member column.");
    }
    groups.emplace_back(members.begin(), members.end());
  }
  const size_t start = op->ncol_used();
  const size_t row_start = op->nrow_used();
  Rcpp::IntegerVector columns(groups.size());
  for (size_t k = 0; k < groups.size(); ++k) {
    const int col = static_cast<int>(op->ncol_used());
    columns[k] = col;
    op->_obj.push_back(0.0);
    op->_vtype.push_back("C");
    op->_lb.push_back(0.0);
    op->_ub.push_back(1.0);
  }
  if (!groups.empty()) {
    op->register_variable_block("joint_effects", start, op->ncol_used(), "exact_AND;shared_across_features");
    const size_t block = op->beginConstraintBlock("joint_effects", "exact_AND");
    for (size_t k = 0; k < groups.size(); ++k) {
      const int y = columns[k];
      for (int col : groups[k]) {
        op->addRow({y, col}, {1.0, -1.0}, "<=", 0.0,
                   "joint_upper_" + std::to_string(k) + "_" + std::to_string(col));
      }
      std::vector<int> cols = groups[k];
      std::vector<double> values(cols.size(), -1.0);
      cols.push_back(y);
      values.push_back(1.0);
      op->addRow(cols, values, ">=", 1.0 - groups[k].size(), "joint_lower_" + std::to_string(k));
    }
    op->endConstraintBlock(block);
  }
  return Rcpp::List::create(Rcpp::Named("columns0") = columns,
                           Rcpp::Named("n_variables") = groups.size(),
                           Rcpp::Named("n_constraints") = op->nrow_used() - row_start);
}

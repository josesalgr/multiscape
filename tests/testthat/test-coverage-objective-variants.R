make_coverage_objective_problem <- function(with_profit = FALSE) {
  p <- make_round3_action_problem(with_effects = TRUE)
  if (isTRUE(with_profit)) {
    p <- multiscape::add_profit(
      p, c(conservation = 3, restoration = 6)
    )
  }
  p |>
    multiscape::add_constraint_targets_absolute(
      data.frame(feature = c(1, 2), target = c(1, 1))
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)
}


test_that("filtered benefit and loss objectives compile and solve", {
  skip_if_no_cbc()

  benefit <- make_coverage_objective_problem() |>
    multiscape::add_objective_max_benefit(
      actions = "restoration", features = "sp1", alias = "benefit"
    )
  benefit_out <- multiscape::solve(benefit)
  expect_s3_class(benefit_out, "SolutionSet")
  expect_true(is.finite(multiscape::get_objectives(benefit_out)$benefit))

  loss <- make_coverage_objective_problem() |>
    multiscape::add_objective_min_loss(
      actions = "conservation", features = "sp2", alias = "loss"
    )
  loss_out <- multiscape::solve(loss)
  expect_s3_class(loss_out, "SolutionSet")
  expect_true(is.finite(multiscape::get_objectives(loss_out)$loss))
})


test_that("profit objective variants compile and solve with action filters", {
  skip_if_no_cbc()

  profit <- make_coverage_objective_problem(with_profit = TRUE) |>
    multiscape::add_objective_max_profit(
      actions = "restoration", alias = "profit"
    )
  profit_out <- multiscape::solve(profit)
  expect_s3_class(profit_out, "SolutionSet")
  expect_true(is.finite(multiscape::get_objectives(profit_out)$profit))

  net <- make_coverage_objective_problem(with_profit = TRUE) |>
    multiscape::add_objective_max_net_profit(
      actions = "conservation",
      include_pu_cost = FALSE,
      include_action_cost = TRUE,
      alias = "net"
    )
  net_out <- multiscape::solve(net)
  expect_s3_class(net_out, "SolutionSet")
  expect_true(is.finite(multiscape::get_objectives(net_out)$net))
})


test_that("intervention impact objective solves selected action-feature pairs", {
  skip_if_no_cbc()

  impact <- make_coverage_objective_problem() |>
    multiscape::add_objective_min_intervention_impact(
      impact_col = "amount",
      features = "sp1",
      actions = "restoration",
      alias = "impact"
    )
  out <- multiscape::solve(impact)
  expect_s3_class(out, "SolutionSet")
  expect_true(is.finite(multiscape::get_objectives(out)$impact))
})


test_that("area, budget and lock constraints compile together", {
  skip_if_no_cbc()

  p <- make_round3_action_problem(with_effects = TRUE)
  p$data$dist_actions$action_area <- 1
  p <- p |>
    multiscape::add_constraint_targets_relative(0.05) |>
    multiscape::add_constraint_area(
      area = 1, sense = "min", actions = "restoration",
      name = "restore_area"
    ) |>
    multiscape::add_constraint_area(
      area = 4, sense = "max", actions = "conservation",
      name = "protect_area"
    ) |>
    multiscape::add_constraint_budget(
      budget = 20, sense = "max",
      include_pu_cost = TRUE, include_action_cost = TRUE,
      name = "total_budget"
    ) |>
    multiscape::add_constraint_locked_planning_units(
      locked_in = 1, locked_out = 4
    ) |>
    multiscape::add_constraint_locked_actions(
      locked_in = data.frame(pu = 1, action = "conservation"),
      locked_out = data.frame(pu = 4, action = "restoration")
    ) |>
    multiscape::add_objective_min_cost(
      include_pu_cost = TRUE,
      include_action_cost = FALSE,
      alias = "cost"
    ) |>
    multiscape::set_solver_cbc(gap_limit = 0, verbose = FALSE)

  expect_no_error(compiled <- multiscape::compile_model(p))
  expect_s3_class(compiled, "Problem")
})

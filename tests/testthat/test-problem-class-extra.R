test_that("Problem class summaries cover configured methods and constraints", {
  p0 <- make_round4_problem()
  expect_equal(multiscape:::.pa_data_status_text(p0), "not built yet (will build in solve())")
  expect_equal(multiscape:::.pa_data_solver_text(p0), "not set (auto)")
  expect_equal(multiscape:::.pa_preview_text(character(0)), "none")
  expect_equal(multiscape:::.pa_preview_text(letters[1:5], max_show = 3, quote = FALSE), "a, b, c, ...")

  feat_sum <- multiscape:::.pa_features_summary(p0)
  expect_equal(feat_sum$n, 2L)
  expect_match(feat_sum$preview, "sp1")

  p1 <- p0 |>
    multiscape::add_actions(
      actions = data.frame(id = c("conservation", "restoration")),
      cost = c(conservation = 1, restoration = 2)
    ) |>
    multiscape::add_constraint_targets_relative(0.1) |>
    multiscape::add_constraint_area(area = 1, sense = "max") |>
    multiscape::add_constraint_budget(budget = 2, sense = "max") |>
    multiscape::add_constraint_locked_planning_units(locked_in = 1, locked_out = 4) |>
    multiscape::add_objective_min_cost(alias = "cost") |>
    multiscape::add_objective_max_benefit(alias = "benefit") |>
    multiscape::set_method_weighted_sum(
      aliases = c("cost", "benefit"),
      runs = multiscape::set_runs_grid(2)
    ) |>
    multiscape::set_solver_cbc(verbose = FALSE)

  act_sum <- multiscape:::.pa_actions_summary(p1)
  expect_equal(act_sum$n, 2L)

  targets_sum <- multiscape:::.pa_targets_summary(p1)
  expect_equal(targets_sum$n_targets, 2L)
  expect_true(length(targets_sum$preview) > 0L)

  cons <- multiscape:::.pa_constraints_summary(p1)
  expect_equal(cons$area_constraints, 1L)
  expect_equal(cons$budget_constraints, 1L)
  expect_equal(cons$pu_locked_in, 1L)
  expect_equal(cons$pu_locked_out, 1L)

  method <- multiscape:::.pa_method_summary(p1)
  expect_true(method$is_set)
  expect_match(method$text, "weighted")
  expect_equal(multiscape:::.pa_model_checks_text(p1), "ok")
  expect_equal(multiscape:::.pa_data_solver_text(p1), "cbc")
})


test_that("Problem class summaries cover missing actions, effects, and incomplete method states", {
  p <- make_round4_problem()

  expect_equal(multiscape:::.pa_actions_summary(p)$n, 0L)
  expect_equal(multiscape:::.pa_actions_summary(p)$preview, "none")

  eff0 <- multiscape:::.pa_effects_summary(p)
  expect_equal(eff0$n_effects, 0L)
  expect_equal(eff0$n_profit, 0L)
  expect_equal(eff0$effect_mode, "none")

  expect_equal(multiscape:::.pa_model_checks_text(p), "incomplete (no objective registered)")

  p_multi_no_method <- make_round4_mo_problem()
  p_multi_no_method$data$method <- NULL
  expect_equal(
    multiscape:::.pa_model_checks_text(p_multi_no_method),
    "incomplete (multiple objectives registered but no MO method selected)"
  )

  p_effects <- make_round4_mo_problem()
  eff <- multiscape:::.pa_effects_summary(p_effects)
  expect_true(eff$n_effects > 0L)
  expect_true(eff$effect_mode %in% c("benefit only", "loss only", "benefit + loss", "all zero"))
})

test_that("Problem class summary helpers cover empty, legacy, and configured states", {
  p <- make_round4_problem(with_actions = TRUE)

  expect_identical(multiscape:::.pa_data_status_text(p), "not built yet (will build in solve())")
  expect_identical(multiscape:::.pa_data_solver_text(p), "not set (auto)")
  expect_equal(multiscape:::.pa_preview_text(character(0)), "none")
  expect_match(multiscape:::.pa_preview_text(letters[1:5], max_show = 2), "\\.\\.\\.")
  expect_equal(multiscape:::.pa_preview_text(c("a", "b"), quote = FALSE), "a, b")

  p_solver <- multiscape::set_solver(p, solver = "cbc", gap_limit = 0.1234)
  expect_identical(multiscape:::.pa_data_solver_text(p_solver), "cbc")

  feat_sum <- multiscape:::.pa_features_summary(p)
  expect_equal(feat_sum$n, 2L)
  expect_match(feat_sum$preview, "sp1")

  p_no_names <- p
  p_no_names$data$features$name <- NULL
  expect_match(multiscape:::.pa_features_summary(p_no_names)$preview, "1")

  act_sum <- multiscape:::.pa_actions_summary(p)
  expect_equal(act_sum$n, 2L)
  expect_match(act_sum$preview, "conservation")

  p_no_action_names <- p
  p_no_action_names$data$actions$name <- NULL
  expect_match(multiscape:::.pa_actions_summary(p_no_action_names)$preview, "conservation")

  p$data$dist_effects <- data.frame(
    pu = c(1, 2, 3),
    action = c("conservation", "restoration", "restoration"),
    feature = c(1, 1, 2),
    amount_after = c(5, 6, 3),
    benefit = c(0, 2, 0),
    loss = c(0, 0, 1),
    stringsAsFactors = FALSE
  )
  expect_identical(multiscape:::.pa_effects_summary(p)$effect_mode, "benefit + loss")

  p$data$targets <- data.frame(
    feature = c(1, 2),
    feature_name = c("sp1", "sp2"),
    target_value = c(3, 4),
    sense = c("ge", "le"),
    stringsAsFactors = FALSE
  )
  tgt <- multiscape:::.pa_targets_summary(p)
  expect_equal(tgt$n_targets, 2L)
  expect_true(any(grepl(">=", tgt$preview)))
  expect_true(any(grepl("<=", tgt$preview)))

  p$data$constraints <- list(
    area = data.frame(actions = c(NA, "restoration"), sense = c("min", "max")),
    budget = list(sense = "max", actions = "restoration")
  )
  p$data$pu$locked_in <- c(TRUE, FALSE, FALSE, TRUE)
  p$data$pu$locked_out <- c(FALSE, TRUE, FALSE, FALSE)
  p$data$dist_actions$status <- c(1L, 2L, 3L, 0L, 0L, 0L, 0L, 0L)[seq_len(nrow(p$data$dist_actions))]

  cs <- multiscape:::.pa_constraints_summary(p)
  expect_equal(cs$area_constraints, 2L)
  expect_equal(cs$budget_constraints, 1L)
  expect_equal(cs$pu_locked_in, 2L)
  expect_equal(cs$pu_locked_out, 1L)
  expect_true(cs$action_locked_in >= 1L)
  expect_true(cs$action_locked_out >= 1L)
})


test_that("Problem method and model check summaries report MO states", {
  p <- make_round4_problem()
  expect_identical(multiscape:::.pa_objectives_summary(p)$n, 0L)
  expect_match(multiscape:::.pa_model_checks_text(p), "no objective")

  p1 <- multiscape::add_objective_min_cost(p, alias = "cost")
  expect_identical(multiscape:::.pa_method_summary(p1)$text, "single-objective")
  expect_identical(multiscape:::.pa_model_checks_text(p1), "ok")

  p2 <- make_round4_mo_problem()
  p2$data$method <- NULL
  expect_match(multiscape:::.pa_model_checks_text(p2), "multiple objectives")

  p2$data$method <- list(type = "epsilon_constraint", primary = "cost")
  expect_match(multiscape:::.pa_method_summary(p2)$text, "epsilon_constraint")

  p2$data$method <- list(type = "weighted", aliases = c("cost", "benefit"))
  expect_match(multiscape:::.pa_method_summary(p2)$text, "weighted")

  p2$data$method <- list(type = "custom_method")
  expect_identical(multiscape:::.pa_method_summary(p2)$text, "custom_method")
})

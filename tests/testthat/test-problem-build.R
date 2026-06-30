test_that("problem-class summaries cover legacy constraint and method branches", {
  p <- make_round4_problem(with_actions = TRUE)

  p$data$constraints <- list(
    area = list(sense = "min", actions = NA_character_),
    budget = list(sense = "max", actions = "restoration")
  )
  p$data$pu$locked_in <- c(TRUE, FALSE, NA, FALSE)
  p$data$pu$locked_out <- c(FALSE, TRUE, FALSE, NA)
  p$data$dist_actions$status <- c(1L, 2L, 3L, 0L, 0L, 0L, 0L, 0L)

  cs <- multiscape:::.pa_constraints_summary(p)
  expect_equal(cs$area_constraints, 1L)
  expect_equal(cs$budget_constraints, 1L)
  expect_equal(cs$pu_locked_in, 1L)
  expect_equal(cs$pu_locked_out, 1L)
  expect_equal(cs$action_locked_in, 2L)
  expect_equal(cs$action_locked_out, 1L)
  expect_equal(cs$area_actions, "all")
  expect_equal(cs$budget_actions, "restoration")

  p$data$objectives <- list(
    cost = list(objective_id = "minimizeCosts"),
    benefit = list(objective_id = "maximizeBenefits")
  )
  expect_match(
    multiscape:::.pa_model_checks_text(p),
    "multiple objectives"
  )

  p$data$method <- list(type = "epsilon_constraint", primary = "cost")
  expect_match(multiscape:::.pa_method_summary(p)$text, "primary: cost")
  expect_equal(multiscape:::.pa_model_checks_text(p), "ok")

  p$data$method <- list(type = "weighted", aliases = c("cost", "benefit"))
  expect_match(multiscape:::.pa_method_summary(p)$text, "weighted")
})


test_that("build-model table preparation filters invalid action rows without solving", {
  p <- make_round4_problem(with_actions = TRUE)

  da <- p$data$dist_actions
  da$status <- 0L
  da$status[1] <- 3L
  da$internal_pu[2] <- NA_integer_
  da$cost[3] <- NA_real_
  p$data$dist_actions <- da

  out <- multiscape:::.pa_build_model_prepare_tables(p)

  expect_s3_class(out, "Problem")
  expect_true(is.data.frame(out$data$dist_actions_model))
  expect_lt(nrow(out$data$dist_actions_model), nrow(da))
  expect_true("internal_row" %in% names(out$data$dist_actions_model))
  expect_true(all(is.finite(out$data$dist_actions_model$cost)))
  expect_false(any(out$data$dist_actions_model$status == 3L))
})


test_that("build-model objective requirement checks cover common missing-input errors", {
  p_no_actions <- make_round4_problem(with_actions = FALSE)
  p_no_actions$data$model_args <- list(
    model_type = "maximizeBenefits",
    objective_args = list(benefit_col = "benefit")
  )
  p_no_actions$data$dist_actions_model <- data.frame()
  p_no_actions$data$dist_effects_model <- data.frame()

  expect_error(
    multiscape:::.pa_build_model_validate_objective_requirements(p_no_actions),
    "requires actions"
  )

  p_actions_no_effects <- make_round4_problem(with_actions = TRUE)
  p_actions_no_effects$data$model_args <- list(
    model_type = "minimizeCosts",
    objective_args = list()
  )
  p_actions_no_effects$data$dist_actions_model <- p_actions_no_effects$data$dist_actions
  p_actions_no_effects$data$dist_effects_model <- data.frame()
  p_actions_no_effects$data$targets <- data.frame(
    feature = 1L,
    target_value = 1,
    stringsAsFactors = FALSE
  )

  expect_error(
    multiscape:::.pa_build_model_validate_objective_requirements(p_actions_no_effects),
    "no action effects"
  )
})

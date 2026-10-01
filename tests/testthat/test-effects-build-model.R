test_that("build_model helpers cover implicit conservation and defensive table preparation", {
  p <- make_round4_problem()

  expect_true(multiscape:::.pa_needs_implicit_conservation_model(p))
  implicit <- multiscape:::.pa_add_implicit_conservation_model(p)
  expect_false(multiscape:::.pa_needs_implicit_conservation_model(implicit))
  expect_true(isTRUE(implicit$data$meta$implicit_actions))
  expect_true(isTRUE(implicit$data$meta$implicit_effects))
  expect_true(nrow(implicit$data$dist_actions) > 0L)
  expect_true(nrow(implicit$data$dist_effects) > 0L)

  already <- make_round4_problem(with_actions = TRUE)
  unchanged <- multiscape:::.pa_add_implicit_conservation_model(already)
  expect_equal(nrow(unchanged$data$actions), nrow(already$data$actions))

  broken <- p
  broken$data$pu$internal_id <- NULL
  expect_error(multiscape:::.pa_add_implicit_conservation_model(broken), "internal_id")

  x <- make_round4_problem(with_actions = TRUE)
  x$data$dist_actions$status[1] <- 3L
  x$data$dist_actions$cost[2] <- NA_real_
  x$data$dist_actions$internal_pu[3] <- NA_integer_
  x$data$dist_effects <- data.frame(
    pu = c(1, 99),
    action = c("restoration", "restoration"),
    feature = c(1, 1),
    benefit = c(1, 2),
    loss = c(0, 0),
    stringsAsFactors = FALSE
  )
  x$data$dist_profit <- data.frame(
    pu = c(1, 99),
    action = c("restoration", "restoration"),
    profit = c(5, 6),
    stringsAsFactors = FALSE
  )

  prepared <- multiscape:::.pa_build_model_prepare_tables(x)
  expect_true(all(prepared$data$dist_actions_model$status != 3L))
  expect_true(all(is.finite(prepared$data$dist_actions_model$cost)))
  expect_true("internal_row" %in% names(prepared$data$dist_actions_model))
  expect_true(nrow(prepared$data$dist_effects_model) <= nrow(x$data$dist_effects))
  expect_true(is.data.frame(prepared$data$dist_profit_model))

  dup <- make_round4_problem(with_actions = TRUE)
  dup$data$dist_actions <- rbind(dup$data$dist_actions[1, ], dup$data$dist_actions[1, ])
  expect_error(multiscape:::.pa_build_model_prepare_tables(dup), "duplicated")

  out_range <- make_round4_problem(with_actions = TRUE)
  out_range$data$dist_actions$internal_pu[1] <- 999L
  expect_error(multiscape:::.pa_build_model_prepare_tables(out_range), "out of range")
})


test_that("build_model validation helpers catch missing dependencies", {
  p <- make_round4_problem()
  p$data$model_args <- list(model_type = "minimizeCosts")
  p$data$targets <- NULL
  expect_warning(
    multiscape:::.pa_build_model_validate_pipeline_state(p, input_format = "new"),
    "all-zero solution may therefore be optimal"
  )

  p_area <- p
  p_area$data$constraints <- list(
    area = data.frame(sense = "min", value = 1)
  )
  expect_warning(
    multiscape:::.pa_build_model_validate_pipeline_state(p_area, input_format = "new"),
    NA
  )
  p_legacy <- p
  expect_error(
    multiscape:::.pa_build_model_validate_pipeline_state(p_legacy, input_format = "legacy"),
    NA
  )

  p_no_obj <- p
  p_no_obj$data$model_args <- list(model_type = "")
  expect_error(multiscape:::.pa_build_model_validate_objective_requirements(p_no_obj), "No active objective")

  p_need_actions <- p
  p_need_actions$data$model_args <- list(model_type = "maximizeProfit")
  p_need_actions$data$dist_actions_model <- data.frame()
  expect_error(multiscape:::.pa_build_model_validate_objective_requirements(p_need_actions), "requires actions")

  p_need_effects <- make_round4_problem(with_actions = TRUE)
  p_need_effects$data$targets <- data.frame(feature = 1, target_value = 1)
  p_need_effects$data$model_args <- list(model_type = "minimizeCosts")
  p_need_effects$data$dist_actions_model <- p_need_effects$data$dist_actions
  p_need_effects$data$dist_effects_model <- data.frame()
  expect_error(multiscape:::.pa_build_model_validate_objective_requirements(p_need_effects), "no action effects")
})

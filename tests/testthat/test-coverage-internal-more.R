test_that("solve arguments merge stored settings and explicit overrides", {
  get_args <- getFromNamespace(".pa_get_solve_args", "multiscape")
  p <- make_round3_tabular_problem()
  p$data$solve_args <- list(
    solver = "cbc", gap_limit = 0.1254, time_limit = 9,
    cores = 99999L, verbose = FALSE,
    solver_params = list(old = 1)
  )

  out <- get_args(
    p, gap_limit = 0.2, time_limit = 3.3333,
    solution_limit = TRUE, cores = 2, verbose = TRUE,
    name_output_file = "", output_file = FALSE,
    solver_params = list(new = 2)
  )
  expect_identical(out$solver, "cbc")
  expect_equal(out$gap_limit, 0.2)
  expect_equal(out$time_limit, 3.333)
  expect_equal(out$cores, 2L)
  expect_true(out$solution_limit)
  expect_true(out$verbose)
  expect_false(out$output_file)
  expect_identical(out$name_output_file, "output")
  expect_equal(out$solver_params, list(old = 1, new = 2))

  expect_identical(get_args(p, solver = "")$solver, "cbc")
  expect_error(get_args(p, solver = "other"), "Unknown solver")
  expect_error(get_args(p, gap_limit = -1), "gap_limit")
  expect_error(get_args(p, gap_limit = Inf), "gap_limit")
  expect_error(get_args(p, time_limit = -1), "time_limit")
  expect_error(get_args(p, cores = 0), "cores")
  expect_error(get_args(p, solver_params = 1), "must be a list")
})


test_that("effect model helper supports benefit, loss and delta layouts", {
  get_effects <- getFromNamespace(".get_dist_effects_model", "multiscape")
  p <- make_round3_action_problem(with_effects = TRUE)

  b <- get_effects(p, "benefit")
  l <- get_effects(p, "loss")
  d <- get_effects(p, "delta")
  expect_equal(b$effect, b$benefit)
  expect_equal(l$effect, l$loss)
  expect_equal(d$effect, d$benefit - d$loss)
  expect_type(d$internal_pu, "integer")

  empty <- p
  empty$data$dist_effects <- NULL
  empty$data$dist_effects_model <- NULL
  expect_null(get_effects(empty))

  benefit_only <- make_round3_action_problem(with_effects = TRUE)
  benefit_only$data$dist_effects_model <- NULL
  benefit_only$data$dist_effects$loss <- NULL
  expect_equal(
    get_effects(benefit_only, "delta")$effect,
    get_effects(benefit_only, "delta")$benefit
  )
  loss_only <- make_round3_action_problem(with_effects = TRUE)
  loss_only$data$dist_effects_model <- NULL
  loss_only$data$dist_effects$benefit <- NULL
  loss_delta <- get_effects(loss_only, "delta")
  expect_equal(loss_delta$effect, -as.numeric(loss_delta[["loss"]]))

  neither <- make_round3_action_problem(with_effects = TRUE)
  neither$data$dist_effects_model <- NULL
  neither$data$dist_effects$benefit <- NULL
  neither$data$dist_effects$loss <- NULL
  expect_error(get_effects(neither, "delta"), "at least one")
  expect_error(get_effects(neither, "benefit"), "missing column 'benefit'")
  expect_error(get_effects(neither, "loss"), "missing column 'loss'")

  bad_b <- make_round3_action_problem(with_effects = TRUE)
  bad_b$data$dist_effects_model <- NULL
  bad_b$data$dist_effects$benefit[1] <- NA_real_
  expect_error(get_effects(bad_b, "benefit"), "NA or non-finite")
  expect_error(get_effects(bad_b, "delta"), "NA or non-finite")
  bad_l <- make_round3_action_problem(with_effects = TRUE)
  bad_l$data$dist_effects_model <- NULL
  bad_l$data$dist_effects$loss[1] <- Inf
  expect_error(get_effects(bad_l, "loss"), "NA or non-finite")
  expect_error(get_effects(bad_l, "delta"), "NA or non-finite")
})


test_that("model needs are initialized, inferred and explicitly overridden", {
  initialize <- getFromNamespace(".pa_build_model_init_needs", "multiscape")
  infer <- getFromNamespace(".pa_build_model_set_needs_from_objective", "multiscape")
  p <- make_round3_tabular_problem()

  p$data$model_args <- NULL
  initialized <- initialize(p)
  expect_equal(
    initialized$data$model_args$needs,
    list(
      z = FALSE, y_pu = FALSE, y_action = FALSE,
      y_intervention = FALSE, u_intervention = FALSE
    )
  )

  cases <- c(
    minimizeFragmentation = "y_pu",
    minimizeActionFragmentation = "y_action",
    minimizeInterventionFragmentation = "y_intervention",
    minimizeInterventionImpact = "u_intervention"
  )
  for (model_type in names(cases)) {
    q <- p
    q$data$model_args <- list(
      model_type = model_type,
      objective_args = list(
        relation_name = "edges", actions = 2L,
        actions_to_use = 1L
      )
    )
    out <- infer(q)$data$model_args$needs
    expect_true(out[[cases[[model_type]]]])
    expect_true(out$z)
  }

  p$data$model_args <- list(
    model_type = "minimizeActionFragmentation",
    objective_args = list(relation_name = "edge", actions = 2L),
    needs = list(
      z = FALSE, y_action = FALSE, custom = "kept",
      relation_name = "custom-edge", actions_to_use = 1L
    )
  )
  out <- infer(p)$data$model_args$needs
  expect_false(out$z)
  expect_false(out$y_action)
  expect_identical(out$custom, "kept")
  expect_identical(out$relation_name, "custom-edge")
  expect_identical(out$actions_to_use, 1L)
})


test_that("internal id label helpers use names, ids, and fallbacks", {
  feature_names <- getFromNamespace(
    ".pa_feature_names_from_internal_ids", "multiscape"
  )
  action_names <- getFromNamespace(
    ".pa_action_names_from_internal_ids", "multiscape"
  )
  p <- make_round3_action_problem(with_effects = FALSE)

  expect_equal(feature_names(p, c(1, 2, 99)), c("sp1", "sp2", "99"))
  expect_equal(
    action_names(p, c(1, 2, 99)),
    c("Conservation", "Restoration", "99")
  )

  ids <- p
  ids$data$features$name <- NULL
  ids$data$actions$name <- NULL
  expect_equal(feature_names(ids, 1:2), c("1", "2"))
  expect_equal(
    action_names(ids, 1:2), c("conservation", "restoration")
  )

  absent <- p
  absent$data$features <- NULL
  absent$data$actions <- NULL
  expect_equal(feature_names(absent, c(3, 4)), c("3", "4"))
  expect_equal(action_names(absent, c(3, 4)), c("3", "4"))

  malformed <- p
  malformed$data$features$internal_id <- NULL
  malformed$data$actions$internal_id <- NULL
  expect_equal(feature_names(malformed, 1:2), c("1", "2"))
  expect_equal(action_names(malformed, 1:2), c("1", "2"))
})


test_that("solution id helpers cover empty and invalid solution collections", {
  make_ids <- getFromNamespace(".pa_make_solution_ids", "multiscape")
  finalize <- getFromNamespace(".pa_finalize_solution_ids", "multiscape")
  expect_identical(make_ids(0), character())
  expect_identical(make_ids(3, "sol_"), c("sol_1", "sol_2", "sol_3"))
  expect_error(make_ids(-1), "non-negative")
  expect_error(make_ids(NA), "non-negative")

  no_runs <- make_mock_solutionset()
  no_runs$solution$runs <- NULL
  expect_identical(finalize(no_runs), no_runs)

  invalid_solutions <- make_mock_solutionset()
  invalid_solutions$solution$solutions <- list(list(), "bad")
  out <- finalize(invalid_solutions)
  expect_length(out$solution$solutions, 0L)
  expect_true(all(is.na(out$solution$runs$solution_id)))

  outside <- make_mock_solutionset()
  outside$solution$solutions[[1]]$meta$run_id <- 99L
  outside$solution$solutions[[2]]$meta$run_id <- -1L
  out <- finalize(outside)
  expect_length(out$solution$solutions, 0L)
})

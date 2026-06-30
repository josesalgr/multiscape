test_that("AUGMECON validates aliases, legacy arguments, and stored settings", {
  p <- make_round4_mo_problem()

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "",
      runs = multiscape::set_runs_grid(3)
    ),
    "primary"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "missing",
      runs = multiscape::set_runs_grid(3)
    ),
    "not found"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      aliases = c("cost", NA_character_),
      runs = multiscape::set_runs_grid(3)
    ),
    "aliases"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      aliases = c("cost", ""),
      runs = multiscape::set_runs_grid(3)
    ),
    "empty"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      aliases = c("cost", "cost"),
      runs = multiscape::set_runs_grid(3)
    ),
    "duplicates"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      aliases = c("cost", "missing"),
      runs = multiscape::set_runs_grid(3)
    ),
    "Unknown aliases"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      aliases = "benefit",
      runs = multiscape::set_runs_grid(3)
    ),
    "primary"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      aliases = "cost",
      runs = multiscape::set_runs_grid(3)
    ),
    "at least two"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost"
    ),
    "runs"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      runs = multiscape::set_runs_grid(3),
      n_points = 3
    ),
    "either `runs` or deprecated"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      runs = multiscape::set_runs_grid(3),
      lexicographic = NA
    ),
    "lexicographic"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      runs = multiscape::set_runs_grid(3),
      lexicographic_tol = -1
    ),
    "lexicographic_tol"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      runs = multiscape::set_runs_grid(3),
      augmentation = 0
    ),
    "augmentation"
  )

  expect_error(
    multiscape::set_method_augmecon(
      p,
      primary = "cost",
      runs = multiscape::set_runs_grid(3),
      slack_upper_bound = Inf
    ),
    "slack_upper_bound"
  )

  ok <- multiscape::set_method_augmecon(
    p,
    primary = "cost",
    aliases = c("cost", "benefit"),
    runs = multiscape::set_runs_manual(
      data.frame(eps_benefit = c(1, 2))
    ),
    lexicographic = FALSE,
    lexicographic_tol = 0,
    augmentation = 1e-4,
    slack_upper_bound = 100
  )

  expect_equal(ok$data$method$type, "augmecon")
  expect_equal(ok$data$method$primary, "cost")
  expect_equal(ok$data$method$secondary, "benefit")
  expect_false(ok$data$method$lexicographic)
  expect_equal(ok$data$method$augmentation, 1e-4)
  expect_equal(ok$data$method$slack_upper_bound, 100)
})


test_that("selection frequency and similarity cover action and PU fallbacks", {
  s <- make_mock_solutionset()

  freq <- multiscape::selection_frequency(s)
  expect_s3_class(freq, "data.frame")
  expect_true(all(c("pu", "action", "n_selected", "n_solutions", "frequency") %in% names(freq)))
  expect_equal(unique(freq$n_solutions), 2L)
  expect_true(all(freq$frequency >= 0 & freq$frequency <= 1))

  jac_long <- multiscape::selection_similarity(s, metric = "jaccard", format = "long")
  expect_s3_class(jac_long, "data.frame")
  expect_equal(attr(jac_long, "metric"), "jaccard")
  expect_true(all(c("solution_id_1", "solution_id_2", "similarity", "distance") %in% names(jac_long)))
  expect_equal(jac_long$distance, 1 - jac_long$similarity)

  ham_mat <- multiscape::selection_similarity(s, metric = "hamming", format = "matrix")
  expect_true(is.matrix(ham_mat))
  expect_equal(attr(ham_mat, "metric"), "hamming")
  expect_equal(unname(diag(ham_mat)), rep(1, nrow(ham_mat)))
  expect_equal(ham_mat, t(ham_mat), ignore_attr = TRUE)

  expect_error(multiscape::selection_frequency(list()), "SolutionSet")
  expect_error(multiscape::selection_similarity(list()), "SolutionSet")

  s_pu <- s
  s_pu$summary$actions <- NULL
  freq_pu <- multiscape::selection_frequency(s_pu)
  expect_equal(unique(freq_pu$action), "conservation")

  one <- s
  one$solution$runs <- one$solution$runs[1, , drop = FALSE]
  one$solution$solutions <- one$solution$solutions["1"]
  one$summary$actions <- one$summary$actions[one$summary$actions$solution_id == 1, , drop = FALSE]
  one_long <- multiscape::selection_similarity(one, format = "long")
  expect_equal(nrow(one_long), 0L)
  one_mat <- multiscape::selection_similarity(one, format = "matrix")
  expect_equal(one_mat[1, 1], 1)
})


test_that("selection internals validate malformed stored summaries", {
  s <- make_mock_solutionset()

  no_runs <- s
  no_runs$solution$runs <- NULL
  expect_error(multiscape::selection_frequency(no_runs), "run table")

  no_solution_id <- s
  no_solution_id$solution$runs$solution_id <- NULL
  expect_error(multiscape::selection_frequency(no_solution_id), "solution_id|run table")

  no_results <- s
  no_results$summary$actions <- NULL
  no_results$summary$pu <- NULL
  expect_error(multiscape::selection_frequency(no_results), "No planning-unit/action|run table")

  bad_actions <- s
  bad_actions$summary$actions$solution_id <- NULL
  expect_error(multiscape::selection_frequency(bad_actions), "solution_id|run table")
})

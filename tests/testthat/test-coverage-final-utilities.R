test_that("stored run ids support current and legacy solution layouts", {
  stored_ids <- getFromNamespace(".pa_get_stored_run_ids", "multiscape")
  s <- make_mock_solutionset()

  expect_equal(stored_ids(s), 1:2)

  legacy <- make_mock_solutionset()
  names(legacy$solution$solutions) <- c("", "")
  expect_equal(stored_ids(legacy), 1:2)

  nonnumeric <- make_mock_solutionset()
  names(nonnumeric$solution$solutions) <- c("first", "second")
  expect_equal(stored_ids(nonnumeric), 1:2)

  empty <- make_mock_solutionset()
  empty$solution$solutions <- list()
  expect_identical(stored_ids(empty), integer())

  expect_error(stored_ids(list()), "SolutionSet")
})


test_that("fragmentation-variable summary handles absent and populated models", {
  summarize <- getFromNamespace(".pa_model_frag_vars_summary", "multiscape")

  expect_null(summarize(list()))

  p <- make_round3_tabular_problem()
  expect_null(summarize(p))

  p$data$model_list <- list(
    n_y_pu = 2L,
    n_y_actions = 3L,
    y_pu_offset = 10L,
    y_actions_offset = 12L
  )
  out <- summarize(p)

  expect_identical(out$n_y_pu, 2L)
  expect_identical(out$n_y_actions, 3L)
  expect_identical(out$n_y_interventions, 0L)
  expect_identical(out$y_pu_offset, 10L)
  expect_identical(out$y_actions_offset, 12L)
  expect_identical(out$y_interventions_offset, 0L)

  p$data$model_list <- list(n_y_pu = 0L, n_y_actions = 0L)
  expect_null(summarize(p))
})

test_that("comparison normalizers handle tables, factors and nested lists", {
  normalize_table <- getFromNamespace(
    ".pa_normalize_table_for_compare", "multiscape"
  )
  normalize_object <- getFromNamespace(
    ".pa_normalize_object_for_compare", "multiscape"
  )

  x <- data.frame(
    internal_id = 2:1,
    created_at = c("later", "earlier"),
    id = c(2, 1),
    label = factor(c("b", "a")),
    stringsAsFactors = TRUE
  )
  out <- normalize_table(x, key = "id")
  expect_identical(names(out), c("id", "label"))
  expect_identical(out$id, c(1, 2))
  expect_type(out$label, "character")
  expect_null(normalize_table(NULL))

  unordered <- normalize_table(data.frame(b = c(2, 1), a = c("z", "a")))
  expect_identical(names(unordered), c("a", "b"))
  expect_equal(unordered$b, c(1, 2))

  nested <- normalize_object(list(z = factor("x"), a = x))
  expect_identical(names(nested), c("a", "z"))
  expect_identical(nested$z, "x")
  expect_null(normalize_object(NULL))
  expect_identical(normalize_object(3L), 3L)
})


test_that("row and summary binders fill asymmetric structures", {
  bind_rows <- getFromNamespace(".pa_bind_rows_fill", "multiscape")
  append_summaries <- getFromNamespace(
    ".pa_append_summary_tables", "multiscape"
  )

  bound <- bind_rows(data.frame(a = 1), data.frame(b = 2))
  expect_identical(names(bound), c("a", "b"))
  expect_true(is.na(bound$b[1]) && is.na(bound$a[2]))
  expect_equal(bind_rows(list(a = 1), list(a = 2))$a, 1:2)

  out <- append_summaries(
    list(shared = data.frame(a = 1), left = data.frame(x = 1), raw = "x"),
    list(shared = data.frame(b = 2), right = data.frame(y = 2), raw = "y")
  )
  expect_equal(nrow(out$shared), 2L)
  expect_identical(out$left$x, 1)
  expect_identical(out$right$y, 2)
  expect_identical(out$raw, "x")
})


test_that("numeric grouping utilities cover tolerances and invalid vectors", {
  equal <- getFromNamespace(".pa_numeric_vectors_equal", "multiscape")
  group <- getFromNamespace(".pa_group_equal_vectors", "multiscape")

  expect_false(equal(1:2, 1:3))
  expect_true(equal(numeric(), numeric()))
  expect_false(equal(c(1, NA), c(1, 2)))
  expect_false(equal(c(1, Inf), c(1, Inf)))
  expect_true(equal(c(1, 2), c(1 + 1e-8, 2), tolerance = 1e-7))
  expect_false(equal(c(1, 2), c(1.1, 2), tolerance = 1e-7))

  expect_identical(group(list()), integer())
  expect_identical(
    group(list(c(1, 2), c(1, 2), c(3, 4), c(1, 2))),
    c(1L, 1L, 2L, 1L)
  )
})


test_that("solution table remapping updates designs, runs and summaries", {
  remap <- getFromNamespace(".pa_remap_solution_set_tables", "multiscape")
  s <- make_mock_solutionset()
  s$solution$design <- data.frame(run_id = 1:2, eps = c(0, 1))
  s$summary$extra <- data.frame(run_id = 2:1, solution_id = 2:1)
  run_map <- data.frame(old_run_id = 1:2, new_run_id = c(11L, 12L))
  solution_map <- data.frame(
    old_solution_id = 1:2, new_solution_id = c(21L, 22L)
  )

  out <- remap(s, run_map, solution_map)
  expect_equal(out$solution$design$run_id, c(11L, 12L))
  expect_equal(out$solution$runs$solution_id, c(21L, 22L))
  expect_equal(out$summary$extra$run_id, c(12L, 11L))
  expect_equal(out$summary$extra$solution_id, c(22L, 21L))

  unchanged <- make_mock_solutionset()
  unchanged$summary$raw <- "not-a-table"
  expect_identical(remap(unchanged, run_map, solution_map)$summary$raw, "not-a-table")
})


test_that("solution uniqueness validates malformed run and objective tables", {
  s <- make_mock_solutionset()
  expect_error(multiscape::solution_unique(list()), "SolutionSet")
  expect_error(multiscape::solution_unique(s, tolerance = -1), "tolerance")

  no_runs <- make_mock_solutionset()
  no_runs$solution$runs <- NULL
  expect_error(multiscape::solution_unique(no_runs), "No run table")
  no_run_id <- make_mock_solutionset()
  no_run_id$solution$runs$run_id <- NULL
  expect_error(multiscape::solution_unique(no_run_id), "run_id")
  no_solution_id <- make_mock_solutionset()
  no_solution_id$solution$runs$solution_id <- NULL
  expect_error(multiscape::solution_unique(no_solution_id), "solution_id")

  singleton <- make_mock_solutionset()
  singleton$solution$runs$solution_id[2] <- NA_integer_
  out <- multiscape::solution_unique(singleton)
  expect_s3_class(out, "SolutionSet")

  expect_error(
    multiscape::solution_unique(s, by = "objectives", objectives = "unknown"),
    "Unknown objective"
  )
  expect_error(
    multiscape::solution_unique(s, by = "objectives", objectives = ""),
    "at least one"
  )
})

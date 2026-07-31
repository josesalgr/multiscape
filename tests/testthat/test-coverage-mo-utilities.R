test_that("objective-vector normalization supports all norms and degenerate inputs", {
  normalize <- getFromNamespace(".pamo_normalize_vec", "multiscape")
  v <- c(-2, 1, 2)

  expect_equal(normalize(v, "max"), c(-1, 0.5, 1))
  expect_equal(normalize(v, "l1"), v / 5)
  expect_equal(normalize(v, "l2"), v / 3)
  expect_equal(normalize(c(0, 0), "max"), c(0, 0))
  expect_equal(normalize(c(NA, Inf), "l1"), c(NA, Inf))
  expect_error(normalize(v, "unknown"), "arg")
})


test_that("simplex integer compositions enumerate every allocation", {
  compose <- getFromNamespace(
    ".pamo_simplex_integer_compositions",
    "multiscape"
  )

  one <- compose(4, 1)
  expect_identical(one, matrix(4L, nrow = 1L, ncol = 1L))

  out <- compose(3, 3)
  expect_equal(nrow(out), choose(5, 2))
  expect_true(all(rowSums(out) == 3L))
  expect_true(all(out >= 0L))
  expect_identical(storage.mode(out), "integer")
  expect_true(any(apply(out, 1, identical, c(3L, 0L, 0L))))
  expect_true(any(apply(out, 1, identical, c(0L, 0L, 3L))))
})


test_that("solution resolver selects by run and solution identifiers", {
  resolve <- getFromNamespace(".mo_get_solution_from", "multiscape")
  s <- make_mock_solutionset()

  expect_s3_class(resolve(s), "Solution")
  expect_identical(resolve(s, solution_id = 2), s$solution$solutions[["2"]])
  expect_identical(resolve(s, run = 1), s$solution$solutions[["1"]])
  expect_identical(
    resolve(s$solution$solutions[["1"]]),
    s$solution$solutions[["1"]]
  )

  expect_error(resolve(list()), "SolutionSet")
  expect_error(resolve(s, run = 1, solution_id = 1), "either")
  expect_error(resolve(s, solution_id = 0), "positive integer")
  expect_error(resolve(s, solution_id = 99), "No stored solution")
  expect_error(resolve(s, run = 0), "positive integer")
  expect_error(resolve(s, run = 99), "No run found")

  unavailable <- make_mock_solutionset()
  unavailable$solution$runs$solution_id[1] <- NA_integer_
  unavailable$solution$runs$status[1] <- "infeasible"
  expect_error(resolve(unavailable, run = 1), "status is 'infeasible'")

  dangling <- make_mock_solutionset()
  dangling$solution$runs$solution_id[1] <- 99L
  expect_error(resolve(dangling, run = 1), "not stored")

  empty <- make_mock_solutionset()
  empty$solution$solutions <- list()
  expect_error(resolve(empty), "No stored solutions")

  invalid <- make_mock_solutionset()
  invalid$solution$solutions <- list(not_a_solution = list())
  expect_error(resolve(invalid), "No stored valid solutions")
})


test_that("solution id finalizer repairs run mappings and rejects duplicates", {
  finalize <- getFromNamespace(".pa_finalize_solution_ids", "multiscape")
  s <- make_mock_solutionset()

  s$solution$runs$solution_id <- NULL
  names(s$solution$solutions) <- c("", "")
  out <- finalize(s)
  expect_equal(out$solution$runs$solution_id, c(1L, 2L))
  expect_identical(names(out$solution$solutions), c("1", "2"))
  expect_equal(
    vapply(
      out$solution$solutions,
      function(z) z$meta$solution_id,
      integer(1)
    ),
    c(`1` = 1L, `2` = 2L)
  )

  no_run_id <- make_mock_solutionset()
  no_run_id$solution$runs$run_id <- NULL
  repaired <- finalize(no_run_id)
  expect_equal(repaired$solution$runs$run_id, 1:2)

  no_solutions <- make_mock_solutionset()
  no_solutions$solution$solutions <- NULL
  empty <- finalize(no_solutions)
  expect_true(is.list(empty$solution$solutions))
  expect_length(empty$solution$solutions, 0L)
  expect_true(all(is.na(empty$solution$runs$solution_id)))

  invalid_run <- make_mock_solutionset()
  invalid_run$solution$runs$run_id[1] <- NA_integer_
  expect_error(finalize(invalid_run), "invalid `run_id`")

  duplicated <- make_mock_solutionset()
  duplicated$solution$solutions[[2]]$meta$run_id <- 1L
  expect_error(finalize(duplicated), "same run_id")

  expect_error(finalize(list()), "SolutionSet")
})

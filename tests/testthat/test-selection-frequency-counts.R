test_that("selection frequency retains zero counts and handles sparse duplicates", {
  x <- make_mock_solutionset()
  x$summary$actions <- data.frame(
    solution_id = c(1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L),
    pu = c(1L, 1L, 2L, 3L, 1L, 2L, 3L, 4L),
    action = c("conservation", "conservation", "restoration", "conservation",
               "conservation", "restoration", "conservation", "restoration"),
    selected = c(0, 1, 0, 0, 1, 1, 0, 0)
  )
  expect_identical(multiscape::selection_frequency(x), data.frame(
    pu = 1:4,
    action = c("conservation", "restoration", "conservation", "restoration"),
    n_selected = c(2L, 1L, 0L, 0L),
    n_solutions = rep(2L, 4),
    frequency = c(1, 0.5, 0, 0)
  ))
})

test_that("selection frequency includes pairs that are never selected", {
  x <- make_mock_solutionset()
  x$summary$actions$selected <- 0L
  out <- multiscape::selection_frequency(x)
  expect_identical(out$n_selected, rep(0L, 4))
  expect_identical(out$frequency, rep(0, 4))
  expect_identical(out$n_solutions, rep(2L, 4))
})

test_that("selection frequency agrees with distinct selected solution counts", {
  set.seed(412)
  for (iteration in seq_len(25)) {
    x <- make_mock_solutionset()
    rows <- expand.grid(solution_id = 1:2, pu = 1:4,
                        action = c("conservation", "restoration"))
    rows$selected <- sample(c(-1, 0, 0.5, 1), nrow(rows), replace = TRUE)
    rows <- rows[sample(seq_len(nrow(rows)), 12), ]
    rows <- rbind(rows, rows[sample(seq_len(nrow(rows)), 4), ])
    rows$action <- factor(rows$action)
    x$summary$actions <- rows
    out <- multiscape::selection_frequency(x)
    for (i in seq_len(nrow(out))) {
      selected_ids <- unique(rows$solution_id[
        rows$pu == out$pu[i] & rows$action == out$action[i] & rows$selected > 0
      ])
      expect_identical(out$n_selected[i], as.integer(length(selected_ids)))
      expect_identical(out$frequency[i], length(selected_ids) / 2)
    }
  }
})

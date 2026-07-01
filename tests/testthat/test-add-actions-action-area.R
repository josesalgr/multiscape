test_that("add_actions fills action_area from pu area when available", {
  pu <- data.frame(id = 1:2, area = c(100, 200), cost = 1)
  features <- data.frame(id = 1, name = "f1")
  dist_features <- data.frame(pu = 1:2, feature = 1, amount = 1)

  p <- create_problem(pu, features, dist_features)
  p <- add_actions(p, data.frame(id = "a1"))

  expect_true("action_area" %in% names(p$data$dist_actions))
  expect_equal(p$data$dist_actions$action_area, c(100, 200))
})

test_that("add_actions allows missing action_area silently", {
  pu <- data.frame(id = 1:2, cost = 1)
  features <- data.frame(id = 1, name = "f1")
  dist_features <- data.frame(pu = 1:2, feature = 1, amount = 1)

  p <- create_problem(pu, features, dist_features)

  expect_warning(
    p <- add_actions(p, data.frame(id = "a1")),
    NA
  )

  expect_true(all(is.na(p$data$dist_actions$action_area)))
})

test_that("add_actions uses manual action_area", {
  pu <- data.frame(id = 1:2, area = c(100, 200), cost = 1)
  features <- data.frame(id = 1, name = "f1")
  dist_features <- data.frame(pu = 1:2, feature = 1, amount = 1)

  p <- create_problem(pu, features, dist_features)

  p <- add_actions(
    p,
    data.frame(id = "a1"),
    action_area = data.frame(
      pu = 1:2,
      action = "a1",
      action_area = c(10, 20)
    )
  )

  expect_equal(p$data$dist_actions$action_area, c(10, 20))
})

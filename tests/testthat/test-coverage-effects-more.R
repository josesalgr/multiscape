test_that("add_effects repairs missing action indices and feature labels", {
  p <- make_round3_action_problem(with_effects = FALSE)
  p$data$actions$internal_id <- NULL
  out <- multiscape::add_effects(
    p,
    data.frame(action = "conservation", feature = 1, relative_change = 0)
  )
  expect_identical(out$data$actions$internal_id, 1:2)

  no_names <- make_round3_action_problem(with_effects = FALSE)
  no_names$data$features$name <- NULL
  numeric_out <- multiscape::add_effects(
    no_names,
    data.frame(action = "conservation", feature = 1, relative_change = 1)
  )
  expect_true(all(numeric_out$data$dist_effects$feature %in% 1:2))
  expect_error(
    multiscape::add_effects(
      no_names,
      data.frame(action = "conservation", feature = "sp1", relative_change = 1)
    ),
    "no 'name' column"
  )
  expect_error(
    multiscape::add_effects(
      make_round3_action_problem(FALSE),
      data.frame(action = "conservation", feature = I(list(1)), relative_change = 1)
    ),
    "either numeric ids or character"
  )
})


test_that("add_effects validates baselines, feasibility and raster-list shape", {
  baseline <- make_round3_action_problem(with_effects = FALSE)
  baseline$data$dist_features$amount[1] <- Inf
  expect_error(
    multiscape::add_effects(
      baseline,
      data.frame(action = "conservation", feature = 1, relative_change = 1)
    ),
    "dist_features.*finite"
  )

  locked <- make_round3_action_problem(with_effects = FALSE)
  locked$data$dist_actions$status <- 3L
  expect_error(
    multiscape::add_effects(
      locked,
      data.frame(action = "conservation", feature = 1, relative_change = 1)
    ),
    "All .* locked_out"
  )

  no_match <- make_round3_action_problem(with_effects = FALSE)
  no_match$data$dist_actions <- no_match$data$dist_actions[
    !(no_match$data$dist_actions$pu == 1 &
        no_match$data$dist_actions$action == "conservation"),
  ]
  expect_error(
    multiscape::add_effects(
      no_match,
      data.frame(
        pu = 1, action = "conservation", feature = 1, effect = 1
      )
    ),
    "No rows in effects match feasible"
  )

  skip_if_not_installed("terra")
  p <- make_round3_spatial_problem(action_based = TRUE)
  r <- terra::rast(nrows = 1, ncols = 1, xmin = 0, xmax = 2, ymin = 0, ymax = 2)
  terra::values(r) <- 1
  expect_error(multiscape::add_effects(p, list(r), raster_type = "effect"), "named list")
  expect_error(multiscape::add_effects(p, list(conservation = NULL), raster_type = "effect"))
})

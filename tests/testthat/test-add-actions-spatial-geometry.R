test_that("spatial action intersections are stored and aligned", {
  skip_if_not_installed("sf")
  p <- make_round2_spatial_problem()
  zone <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(
        0.5, 0, 1.5, 0, 1.5, 2, 0.5, 2, 0.5, 0
      ), ncol = 2, byrow = TRUE))),
      crs = sf::st_crs(p$data$pu_sf)
    )
  )

  out <- multiscape::add_actions(
    p, actions = data.frame(id = "restore"),
    include_pairs = list(restore = zone), progress = FALSE, chunk_size = 1L
  )

  expect_s3_class(out$data$dist_actions_sf, "sf")
  expect_named(out$data$dist_actions_sf, c(
    "pu", "action", "internal_pu", "internal_action", "action_area", "geometry"
  ))
  expect_equal(nrow(out$data$dist_actions_sf), nrow(out$data$dist_actions))
  expect_equal(out$data$dist_actions_sf$pu, out$data$dist_actions$pu)
  expect_equal(out$data$dist_actions_sf$action, out$data$dist_actions$action)
  expect_equal(out$data$dist_actions_sf$action_area,
               out$data$dist_actions$action_area)
  expect_equal(as.numeric(sf::st_area(out$data$dist_actions_sf)),
               out$data$dist_actions$action_area, tolerance = 1e-10)
})

test_that("spatial geometry follows exclusions and action-area overrides", {
  skip_if_not_installed("sf")
  p <- make_round2_spatial_problem()
  zone <- sf::st_sf(geometry = sf::st_union(sf::st_geometry(p$data$pu_sf)))

  out <- multiscape::add_actions(
    p, actions = data.frame(id = "restore"),
    include_pairs = list(restore = zone),
    exclude_pairs = data.frame(pu = 2L, action = "restore"),
    action_area = data.frame(pu = 1L, action = "restore", action_area = 0.25),
    progress = FALSE
  )

  expect_false(2L %in% out$data$dist_actions$pu)
  expect_false(2L %in% out$data$dist_actions_sf$pu)
  expect_equal(out$data$dist_actions_sf$action_area,
               out$data$dist_actions$action_area)
  expect_equal(out$data$dist_actions_sf$action_area[
    out$data$dist_actions_sf$pu == 1L
  ], 0.25)
})

test_that("mixed spatial and id action lists retain geometry for spatial rows", {
  skip_if_not_installed("sf")
  p <- make_round2_spatial_problem()
  out <- multiscape::add_actions(
    p, actions = data.frame(id = c("protect", "restore")),
    include_pairs = list(
      protect = c(1L, 3L),
      restore = p$data$pu_sf[c(2, 4), ]
    ),
    progress = FALSE
  )

  expect_equal(unique(out$data$dist_actions_sf$action), "restore")
  expect_equal(out$data$dist_actions_sf$pu, c(2L, 4L))
  expect_equal(nrow(out$data$dist_actions), 4L)
})

test_that("spatial processing controls are validated", {
  p <- make_round2_spatial_problem()
  actions <- data.frame(id = "restore")
  expect_error(multiscape::add_actions(p, actions, progress = NA), "progress")
  expect_error(multiscape::add_actions(p, actions, chunk_size = 0), "chunk_size")
  expect_error(multiscape::add_actions(p, actions, chunk_size = 1.5), "chunk_size")
})

test_that("stored intersections support the spatial group-equity workflow", {
  skip_if_not_installed("sf")
  p <- make_round2_spatial_problem()
  action_zone <- sf::st_sf(
    geometry = sf::st_sfc(sf::st_polygon(list(matrix(c(
      0, 0, 2, 0, 2, 1.5, 0, 1.5, 0, 0
    ), ncol = 2, byrow = TRUE))), crs = sf::st_crs(p$data$pu_sf))
  )
  groups <- sf::st_sf(
    id = c("west", "east"),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(0, 0, 1, 0, 1, 2, 0, 2, 0, 0),
                                     ncol = 2, byrow = TRUE))),
      sf::st_polygon(list(matrix(c(1, 0, 2, 0, 2, 2, 1, 2, 1, 0),
                                     ncol = 2, byrow = TRUE))),
      crs = sf::st_crs(p$data$pu_sf)
    )
  )

  p <- multiscape::add_actions(
    p, actions = data.frame(id = "restore"),
    include_pairs = list(restore = action_zone), progress = FALSE
  ) |>
    multiscape::add_groups(groups)

  group_geom <- groups[, "id", drop = FALSE]
  names(group_geom)[names(group_geom) == "id"] <- "group"
  ga_sf <- suppressWarnings(sf::st_intersection(
    p$data$dist_actions_sf[, c("pu", "action")], group_geom
  ))
  ga <- sf::st_drop_geometry(ga_sf)
  ga$area <- as.numeric(sf::st_area(ga_sf))
  ga <- stats::aggregate(area ~ pu + group + action, ga, sum)

  p <- multiscape::add_group_equity(p, ga, actions = "restore") |>
    multiscape::add_objective_min_group_gini_numerator(alias = "gini")
  built <- multiscape:::.pa_build_model(p)

  expect_s3_class(built, "Problem")
  expect_gt(nrow(built$data$group_equity$group_actions), 0L)
  expect_true(!is.null(built$data$model_registry$vars$group_equity))
})


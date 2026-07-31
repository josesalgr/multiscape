test_that("geometry-derived boundaries cover off-diagonal and self terms", {
  skip_if_not_installed("sf")
  p <- make_round3_spatial_problem()

  with_self <- multiscape::add_spatial_boundary(
    p, geometry = p$data$pu_sf, include_self = TRUE,
    edge_factor = 0.5, weight_multiplier = 2
  )
  rel <- with_self$data$spatial_relations$boundary
  expect_true(any(rel$internal_pu1 == rel$internal_pu2))
  expect_true(any(rel$internal_pu1 != rel$internal_pu2))

  without_self <- multiscape::add_spatial_boundary(
    p, geometry = p$data$pu_sf, include_self = FALSE
  )
  expect_true(all(
    without_self$data$spatial_relations$boundary$internal_pu1 !=
      without_self$data$spatial_relations$boundary$internal_pu2
  ))

  expect_error(
    multiscape::add_spatial_boundary(p, geometry = data.frame(id = 1:4)),
    "sf object"
  )
  bad <- p$data$pu_sf
  bad$id[1] <- 99
  expect_error(
    multiscape::add_spatial_boundary(p, geometry = bad),
    "does not match"
  )
})


test_that("sf action zones determine feasible pairs and intersected area", {
  skip_if_not_installed("sf")
  p <- make_round3_spatial_problem()
  zones <- list(
    protect = p$data$pu_sf[c(1, 2), ],
    restore = sf::st_sf(
      geometry = sf::st_sfc(
        sf::st_polygon(list(matrix(
          c(0.5, 0.5, 2, 0.5, 2, 2, 0.5, 2, 0.5, 0.5),
          ncol = 2, byrow = TRUE
        ))),
        crs = sf::st_crs(p$data$pu_sf)
      )
    )
  )

  out <- multiscape::add_actions(
    p,
    actions = data.frame(id = c("protect", "restore")),
    include_pairs = zones,
    cost = c(protect = 1, restore = 2)
  )
  expect_gt(nrow(out$data$dist_actions), 2L)
  expect_true(all(is.finite(out$data$dist_actions$action_area)))
  expect_true(all(out$data$dist_actions$action_area >= 0))

  zones$protect <- NULL
  out_null <- multiscape::add_actions(
    p,
    actions = data.frame(id = c("protect", "restore")),
    include_pairs = zones,
    cost = c(protect = 1, restore = 2)
  )
  expect_true(all(out_null$data$dist_actions$action == "restore"))
})


test_that("sf zones can lock action pairs in and out", {
  skip_if_not_installed("sf")
  p <- make_round3_spatial_problem(action_based = TRUE)

  out <- multiscape::add_constraint_locked_actions(
    p,
    locked_in = list(conservation = p$data$pu_sf[1, ]),
    locked_out = list(restoration = p$data$pu_sf[4, ])
  )
  da <- out$data$dist_actions
  expect_equal(
    da$status[da$pu == 1 & da$action == "conservation"], 2L
  )
  expect_equal(
    da$status[da$pu == 4 & da$action == "restoration"], 3L
  )

  expect_error(
    multiscape::add_constraint_locked_actions(
      p,
      locked_in = list(
        conservation = p$data$pu_sf[1, ],
        restoration = data.frame(id = 1)
      )
    ),
    "must be an sf object"
  )
})


test_that("raster effects are extracted over vector planning units", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")
  p <- make_round3_spatial_problem(action_based = TRUE)

  template <- terra::rast(
    nrows = 2, ncols = 2, xmin = 0, xmax = 2, ymin = 0, ymax = 2,
    crs = "EPSG:3857"
  )
  make_effect <- function(v1, v2) {
    r <- c(terra::rast(template), terra::rast(template))
    terra::values(r) <- cbind(rep(v1, 4), rep(v2, 4))
    names(r) <- c("sp1", "sp2")
    r
  }
  effects <- list(
    conservation = make_effect(5, 2),
    restoration = make_effect(7, 6)
  )

  expect_error(
    multiscape::add_effects(p, list(unknown = effects[[1]])),
    "unknown action ids"
  )
  expect_error(
    multiscape::add_effects(p, list(conservation = data.frame(x = 1))),
    "SpatRaster"
  )
  malformed <- effects
  malformed$conservation <- template
  expect_error(
    multiscape::add_effects(p, malformed),
    "layers"
  )
})

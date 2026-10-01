test_that("semantic inputs give equivalent coefficients without warnings", {
  p <- reference_problem()
  tbl <- data.frame(pu = 1, action = "restore", feature = "habitat")
  for (nm in c("effect", "outcome", "relative_change")) {
    b <- tbl
    b[[nm]] <- switch(nm, effect = 30, outcome = 130, relative_change = 0.3)
    expect_warning(q <- add_effects(p, b), NA)
    expect_equal(q$data$dist_effects$effect, 30)
    expect_equal(q$data$dist_effects$action_outcome, 130)
    expect_equal(q$data$dist_effects$reference_amount, 100)
    expect_equal(q$data$dist_effects$amount_after, 130)
  }
  expect_null(p$data$dist_effects)
})

test_that("compact semantic tables expand including zero references", {
  p <- reference_problem()
  b <- data.frame(action = "restore", feature = 1, relative_change = 0.3)
  q <- add_effects(p, b)
  expect_equal(q$data$dist_effects$effect, c(30, 0))
  b$relative_change <- NULL
  b$outcome <- 20
  q <- add_effects(p, b)
  expect_equal(q$data$dist_effects$effect, c(-80, 20))
  b$outcome <- NULL
  b$effect <- 20
  expect_equal(add_effects(p, b)$data$dist_effects$effect, c(20, 20))
})


test_that("semantic columns reject invalid numeric values and negative outcomes", {
  p <- reference_problem()
  keys <- data.frame(pu = 1, action = "restore", feature = 1)
  for (column in c("effect", "outcome", "relative_change")) {
    b <- keys
    b[[column]] <- NA_real_
    expect_error(add_effects(p, b), "missing")
    b[[column]] <- Inf
    expect_error(add_effects(p, b), "finite")
    b[[column]] <- "130"
    expect_error(add_effects(p, b), "numeric")
    b[[column]] <- switch(column, effect = -101, outcome = -1, relative_change = -1.01)
    expect_error(add_effects(p, b), "negative")
  }
})

test_that("semantic columns reject ambiguity and compact tables validate their keys", {
  p <- reference_problem()
  keys <- data.frame(pu = 1, action = "restore", feature = 1)
  for (columns in list(c("effect", "outcome"), c("effect", "relative_change"),
                       c("outcome", "relative_change"))) {
    b <- keys
    b[[columns[1]]] <- 1
    b[[columns[2]]] <- 1
    expect_error(add_effects(p, b), "exactly one")
  }
  compact <- data.frame(action = "restore", feature = 1, effect = 30)
  expect_error(add_effects(p, rbind(compact, compact)), "duplicated")
  p$data$dist_actions$status <- c(1L, 3L)
  expect_equal(add_effects(p, compact)$data$dist_effects$pu, 1L)
  compact$feature <- "unknown"
  expect_error(add_effects(p, compact), "Unknown feature name")
  expect_error(add_effects(p, effects = "bad"), "Unsupported type")
})

test_that("new raster inputs align planning units and features", {
  skip_if_not_installed("terra")
  p <- create_problem(
    pu = data.frame(id = 1:2, cost = 1),
    features = data.frame(id = 1:2, name = c("habitat", "carbon")),
    dist_features = data.frame(pu = rep(1:2, 2), feature = rep(1:2, each = 2),
                               amount = c(100, 200, 300, 400))
  ) |> add_actions(actions = data.frame(id = "restore"))
  z <- terra::rast(nrows = 1, ncols = 2, xmin = 0, xmax = 2, ymin = 0, ymax = 1)
  terra::values(z) <- 1:2
  p$data$pu_raster_id <- z
  r <- c(z, z)
  terra::values(r) <- matrix(c(10, 20, 30, 40), nrow = 2)
  expect_warning(q <- add_effects(p, list(restore = r), raster_aggregation = "sum"), NA)
  de <- q$data$dist_effects
  expect_equal(de$effect, c(10, 20, 30, 40))
  terra::values(r) <- matrix(c(110, 220, 330, 440), nrow = 2)
  expect_warning(q <- add_effects(p, list(restore = r), raster_type = "outcome"), NA)
  expect_equal(q$data$dist_effects$effect, c(10, 20, 30, 40))
})

test_that("polygon raster extraction supports sum and mean", {
  r <- terra::rast(nrows = 1, ncols = 2, xmin = 0, xmax = 2,
                   ymin = 0, ymax = 1, crs = "EPSG:3857")
  terra::values(r) <- c(40, 60)
  names(r) <- "habitat"
  polygon <- sf::st_polygon(list(matrix(c(0, 0, 2, 0, 2, 1, 0, 1, 0, 0),
                                       ncol = 2, byrow = TRUE)))
  pu <- sf::st_sf(id = 1L, cost = 1, geometry = sf::st_sfc(polygon, crs = 3857))
  p <- create_problem(pu = pu, features = r, cost = "cost") |>
    add_actions(actions = data.frame(id = "restore"))
  terra::values(r) <- c(20, 30)
  summed <- add_effects(p, list(restore = r), raster_aggregation = "sum")
  averaged <- add_effects(p, list(restore = r), raster_aggregation = "mean")
  expect_equal(summed$data$dist_effects$effect, 50)
  expect_equal(averaged$data$dist_effects$effect, 25)
  terra::values(r) <- c(60, 90)
  outcome <- add_effects(p, list(restore = r), raster_aggregation = "sum",
                         raster_type = "outcome")
  expect_equal(outcome$data$dist_effects, summed$data$dist_effects)
})

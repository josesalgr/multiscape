test_that("shipped tabular example data are loadable and consistent", {
  data("sim_pu", package = "multiscape")
  data("sim_features", package = "multiscape")
  data("sim_dist_features", package = "multiscape")

  expect_s3_class(sim_pu, "data.frame")
  expect_s3_class(sim_features, "data.frame")
  expect_s3_class(sim_dist_features, "data.frame")

  expect_true(all(c("id", "cost") %in% names(sim_pu)))
  expect_true("id" %in% names(sim_features))
  expect_true(all(c("pu", "feature", "amount") %in% names(sim_dist_features)))

  expect_true(all(sim_dist_features$pu %in% sim_pu$id))
  expect_true(all(sim_dist_features$feature %in% sim_features$id))
  expect_true(all(is.finite(sim_dist_features$amount)))
})

test_that("load_sim_features_raster returns the packaged SpatRaster", {
  skip_if_not_installed("terra")

  r <- multiscape::load_sim_features_raster()

  expect_s4_class(r, "SpatRaster")
  expect_gt(terra::nlyr(r), 0L)
  expect_gt(terra::ncell(r), 0L)
})

test_that("load_sim_multiaction returns complete and consistent inputs", {

  example_data <- multiscape::load_sim_multiaction()

  expect_named(
    example_data,
    c("planning_units", "features", "dist_features", "actions", "action_costs", "effect_assumptions", "effects")
  )
  expect_s3_class(example_data$planning_units, "sf")
  expect_equal(nrow(example_data$planning_units), 64L)
  expect_equal(nrow(example_data$features), 2L)
  expect_equal(nrow(example_data$actions), 2L)
  expect_true(all(example_data$dist_features$pu %in% example_data$planning_units$id))
  expect_true(all(example_data$dist_features$feature %in% example_data$features$id))
  expect_true(all(example_data$action_costs$pu %in% example_data$planning_units$id))
  expect_true(all(example_data$action_costs$action %in% example_data$actions$id))
  expect_named(example_data$effects, c("pu", "action", "feature", "delta"))
  expect_true(all(example_data$effects$pu %in% example_data$planning_units$id))
  expect_true(all(example_data$effects$action %in% example_data$actions$id))
  expect_true(all(example_data$effects$feature %in% example_data$features$id))
})

test_that("load_meseta provides readable action ids and preserves numerical inputs", {
  expected <- readRDS(system.file("extdata", "meseta_iberica_inputs.rds", package = "multiscape"))
  actual <- load_meseta()
  expect_identical(actual$actions$id, expected$actions$name)
  expect_identical(actual$provenance$action_id_lookup,
    data.frame(source_id = expected$actions$id, id = expected$actions$name))
  expect_true(all(actual$action_costs$action %in% actual$actions$id))
  expect_true(all(actual$outcomes$action %in% actual$actions$id))
  # Reversing only the documented identifier conversion restores every input.
  restored <- actual[names(expected)]
  restored$actions$id <- expected$actions$id
  for (table in c("action_costs", "outcomes")) {
    restored[[table]]$action <- expected$actions$id[
      match(restored[[table]]$action, actual$actions$id)]
  }
  restored$provenance$action_id_lookup <- NULL
  expect_identical(restored, expected)
  expect_named(actual, c("planning_units", "features", "dist_features", "actions",
    "action_costs", "outcomes", "targets", "boundary", "provenance", "maps"))
  expect_s3_class(actual$planning_units, "sf")
  expect_equal(nrow(actual$planning_units), 11109L)
  expect_equal(nrow(actual$features), 155L)
  expect_equal(nrow(actual$actions), 4L)
})

test_that("ecosystem-services loader preserves the paired historical inputs", {
  historical <- new.env(parent = emptyenv())
  utils::data("sim_pu_sf", package = "multiscape", envir = historical)
  actual <- load_ecosystem_services()
  expect_named(actual, c("planning_units", "feature_raster"))
  expect_identical(actual$planning_units, historical$sim_pu_sf)
  expect_equal(nrow(actual$planning_units), 30496L)
  old_raster <- load_sim_features_raster()
  expect_true(terra::compareGeom(actual$feature_raster, old_raster))
  expect_identical(names(actual$feature_raster), names(old_raster))
  cells <- unique(as.integer(seq(1, terra::ncell(old_raster), length.out = 100)))
  expect_equal(terra::extract(actual$feature_raster, cells), terra::extract(old_raster, cells))
})


test_that("Meseta preview maps preserve locations, costs and sparse outcomes", {
  meseta <- load_meseta()
  expect_named(meseta$maps, c("costs", "DENMINO", "CISJUNC", "MLE", "AGRICULTURE", "ROS"))
  for (map in meseta$maps) {
    expect_s3_class(map, "sf")
    expect_equal(nrow(map), nrow(meseta$planning_units))
    expect_named(sf::st_drop_geometry(map), meseta$actions$name)
    expect_identical(row.names(map), as.character(meseta$planning_units$id))
    expect_identical(sf::st_geometry(map), sf::st_geometry(meseta$planning_units))
  }

  costs <- as.matrix(sf::st_drop_geometry(meseta$maps$costs))
  cost_rows <- cbind(match(meseta$action_costs$pu, meseta$planning_units$id),
    match(meseta$action_costs$action, meseta$actions$id))
  expect_equal(unname(costs[cost_rows]), meseta$action_costs$cost)
  expect_false(anyNA(costs))

  for (feature in setdiff(names(meseta$maps), "costs")) {
    feature_id <- meseta$features$id[match(feature, meseta$features$name)]
    supplied <- meseta$outcomes[meseta$outcomes$feature == feature_id, ]
    values <- as.matrix(sf::st_drop_geometry(meseta$maps[[feature]]))
    supplied_rows <- cbind(match(supplied$pu, meseta$planning_units$id),
      match(supplied$action, meseta$actions$id))
    expect_equal(unname(values[supplied_rows]), supplied$outcome)
    expected_totals <- vapply(meseta$actions$id,
      function(action) sum(supplied$outcome[supplied$action == action]), numeric(1))
    expect_equal(unname(colSums(values)), unname(expected_totals))
    expect_true(all(values %in% c(0, 1)))
  }
})


test_that("direct Meseta tables reproduce the former README formulation", {
  meseta <- load_meseta()
  raw <- readRDS(system.file("extdata", "meseta_iberica_inputs.rds", package = "multiscape"))
  # Compile a small spatial subset with both paths; no solver is required.
  pu_ids <- unique(c(meseta$dist_features$pu, head(meseta$boundary$pu1, 8), head(meseta$boundary$pu2, 8)))
  feature_id <- meseta$features$id[match("DENMINO", meseta$features$name)]
  build <- function(inputs, old_preparation = FALSE) {
    pu <- inputs$planning_units[inputs$planning_units$id %in% pu_ids, ]
    actions <- inputs$actions
    costs <- inputs$action_costs[inputs$action_costs$pu %in% pu_ids, ]
    outcomes <- inputs$outcomes[inputs$outcomes$pu %in% pu_ids &
      inputs$outcomes$feature == feature_id, ]
    if (old_preparation) {
      pu$cost <- 0
      lookup <- setNames(actions$name, actions$id)
      costs$action <- unname(lookup[as.character(costs$action)])
      outcomes$action <- unname(lookup[as.character(outcomes$action)])
      actions <- data.frame(id = actions$name)
    }
    relation <- inputs$boundary[inputs$boundary$pu1 %in% pu_ids &
      inputs$boundary$pu2 %in% pu_ids, ]
    # The supplied zero credited reference emits the usual absent-feature warnings.
    base <- suppressWarnings(create_problem(pu,
      inputs$features[inputs$features$id == feature_id, ],
      inputs$dist_features[inputs$dist_features$feature == feature_id, ], cost = "cost"))
    p <- base |>
      add_actions(actions = actions, cost = costs) |>
      add_effects(effects = outcomes) |>
      add_constraint_action_cardinality(count = 1, sense = "max") |>
      add_constraint_targets_absolute(data.frame(feature = feature_id, target = 1)) |>
      add_spatial_relations(relation, name = "boundary") |>
      add_objective_min_cost(include_pu_cost = FALSE, alias = "cost") |>
      add_objective_min_fragmentation_action(relation_name = "boundary", alias = "spatial") |>
      set_method_weighted_sum(aliases = c("cost", "spatial"),
        runs = set_runs_manual(data.frame(weight_cost = 1, weight_spatial = 0.5)),
        normalize_weights = FALSE, objective_scaling = FALSE)
    compiled <- compile_model(p)
    specs <- multiscape:::.pamo_get_objective_specs(compiled, c("cost", "spatial"))
    vectors <- lapply(specs, function(spec) {
      ir <- multiscape:::.pamo_objective_to_ir(compiled, spec)
      multiscape:::.pamo_objvec_from_ir(compiled, ir)
    })
    list(model = compiled$data$model_list, objectives = vectors)
  }
  direct <- build(meseta)
  expect_true(any(direct$objectives[[1]] != 0))
  expect_true(any(direct$objectives[[2]] != 0))
  expect_equal(direct, build(raw, old_preparation = TRUE))
})

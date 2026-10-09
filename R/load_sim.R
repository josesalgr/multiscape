#' Example feature raster
#'
#' Load the example feature raster shipped with the package. This access is
#' retained for compatibility; use [load_ecosystem_services()] to load its
#' matching planning units and raster together.
#'
#' @return A `terra::SpatRaster`.
#' @export
load_sim_features_raster <- function() {
  path <- system.file("extdata", "sim_features_raster.tif", package = "multiscape")
  terra::rast(path)
}



#' Load the simulated spatial multi-action example
#'
#' Load a compact, deterministic dataset for examples of multi-objective spatial
#' planning. The landscape contains 64 square planning units, two spatially
#' structured features, and two mutually exclusive candidate actions.
#'
#' @return A named list containing:
#' \describe{
#'   \item{\code{planning_units}}{An \code{sf} object with 64 planning units.}
#'   \item{\code{features}}{A feature catalogue.}
#'   \item{\code{dist_features}}{Feature amounts by planning unit.}
#'   \item{\code{actions}}{The action catalogue.}
#'   \item{\code{action_costs}}{Action costs by planning unit and action.}
#'   \item{\code{effect_assumptions}}{Relative-change assumptions by action and feature.}
#'   \item{\code{effects}}{Explicit signed changes by planning unit, action, and feature.}
#' }
#'
#' @examples
#' # Load a complete simulated planning problem.
#' example_data <- load_sim_multiaction()
#' names(example_data)
#' utils::head(example_data$planning_units)
#'
#' @export
load_sim_multiaction <- function() {
  e <- new.env(parent = emptyenv())
  utils::data("sim_multiaction", package = "multiscape", envir = e)
  e$sim_multiaction
}

#' Load the Meseta Iberica spatial action example
#'
#' Load the complete inputs used by the introductory README tutorial. These
#' earlier available data support an adaptation of the Meseta case study, not
#' an exact reproduction of the final 2025 article.
#'
#' @return A named list containing:
#' \describe{
#'   \item{planning_units}{An `sf` object with 11,109 planning units.}
#'   \item{features}{A catalogue of 155 features.}
#'   \item{dist_features}{The explicit comparison reference used in the tutorial.}
#'   \item{actions}{A catalogue of four management strategies, with readable
#'   character identifiers in `id` (also provided in `name`).}
#'   \item{action_costs}{Costs by planning unit and action.}
#'   \item{outcomes}{Outcomes by planning unit, action and feature.}
#'   \item{targets}{Representation targets for all features.}
#'   \item{boundary}{The supplied weighted spatial relation. Replacing it with
#'   a newly derived boundary can change the optimization problem.}
#'   \item{provenance}{Data sources and preparation notes.
#'   `action_id_lookup` records the original numeric `source_id` and the
#'   returned character `id` for each action.}
#'   \item{maps}{Ready-to-plot `sf` views: `costs`, `DENMINO`, `CISJUNC`,
#'   `MLE`, `AGRICULTURE` and `ROS`. Each view contains four strategy columns
#'   and geometry, so `plot()` displays the four action scenarios directly.}
#' }
#' @details
#' The action identifiers in `actions$id`, `action_costs$action` and
#' `outcomes$action` consistently use `Afforestation`, `BAU`, `FarmReturn`
#' and `Firesmart`. The tables can be passed directly to [add_actions()] and
#' [add_effects()], without recoding identifiers. Scripts that explicitly
#' select numeric action identifiers must use these names instead.
#' Original identifiers remain available in `provenance$action_id_lookup`.
#' All amounts, costs, targets, reference values and geometries are preserved.
#' Planning-unit costs are retained; use `include_pu_cost = FALSE` in
#' [add_objective_min_cost()] to count only action implementation costs.
#' Maps are derived when loading, without storing additional copies of
#' geometry in package data.
#' Map columns use the names in `actions$name`; rows follow `planning_units`
#' order, and row names contain planning-unit identifiers.
#'
#' The five feature maps illustrate contrasting action scenarios (three species
#' and two ecosystem-service features), not ecological importance. Missing
#' outcome rows are displayed as zero, following the dataset convention.
#' These maps describe inputs under each action, not optimized selections.
#' @examples
#' meseta <- load_meseta()
#' names(meseta)
#' meseta$actions
#' plot(meseta$maps$costs)
#' plot(meseta$maps$DENMINO)
#' @export
load_meseta <- function() {
  meseta <- readRDS(system.file("extdata", "meseta_iberica_inputs.rds", package = "multiscape"))
  # Use the same readable identifiers in the catalogue and both input tables.
  meseta$provenance$action_id_lookup <- data.frame(
    source_id = meseta$actions$id, id = meseta$actions$name,
    stringsAsFactors = FALSE)
  for (table in c("action_costs", "outcomes")) {
    meseta[[table]]$action <- meseta$actions$name[
      match(meseta[[table]]$action, meseta$actions$id)]
  }
  meseta$actions$id <- meseta$actions$name
  meseta$maps <- .pa_meseta_preview_maps(meseta)
  meseta
}

# Derive compact spatial views while leaving the optimization tables untouched.
.pa_meseta_preview_maps <- function(meseta) {
  pu <- meseta$planning_units
  actions <- meseta$actions
  geometry <- sf::st_geometry(pu)

  make_map <- function(values, column, fill) {
    amounts <- matrix(fill, nrow = nrow(pu), ncol = nrow(actions),
      dimnames = list(as.character(pu$id), actions$name))
    positions <- cbind(match(values$pu, pu$id), match(values$action, actions$id))
    amounts[positions] <- values[[column]]
    sf::st_sf(as.data.frame(amounts, check.names = FALSE), geometry = geometry)
  }

  maps <- list(costs = make_map(meseta$action_costs, "cost", NA_real_))
  for (feature in c("DENMINO", "CISJUNC", "MLE", "AGRICULTURE", "ROS")) {
    feature_id <- meseta$features$id[match(feature, meseta$features$name)]
    values <- meseta$outcomes[meseta$outcomes$feature == feature_id,
      c("pu", "action", "outcome"), drop = FALSE]
    maps[[feature]] <- make_map(values, "outcome", 0)
  }
  maps
}

#' Load the ecosystem-services spatial example
#'
#' Load the paired planning units and feature raster used by the integrated
#' planning vignette. This is a different landscape from both the compact
#' simulated example and Meseta. The vignette derives its feature catalogue
#' and reference amounts from the raster.
#'
#' @return A named list containing:
#' \describe{
#'   \item{planning_units}{An `sf` object with 30,496 planning units, including
#'   cost, area and historical lock columns.}
#'   \item{feature_raster}{A `terra::SpatRaster` with four ecosystem-service layers.}
#' }
#' @examples
#' services <- load_ecosystem_services()
#' nrow(services$planning_units)
#' names(services$feature_raster)
#' @export
load_ecosystem_services <- function() {
  e <- new.env(parent = emptyenv())
  utils::data("sim_pu_sf", package = "multiscape", envir = e)
  list(planning_units = e$sim_pu_sf, feature_raster = load_sim_features_raster())
}

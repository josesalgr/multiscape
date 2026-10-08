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
#'   \item{actions}{A catalogue of four management strategies.}
#'   \item{action_costs}{Costs by planning unit and action.}
#'   \item{outcomes}{Outcomes by planning unit, action and feature.}
#'   \item{targets}{Representation targets for all features.}
#'   \item{boundary}{The supplied weighted spatial relation. Replacing it with
#'   a newly derived boundary can change the optimization problem.}
#'   \item{provenance}{Data sources and preparation notes.}
#' }
#' @examples
#' meseta <- load_meseta()
#' names(meseta)
#' meseta$actions
#' @export
load_meseta <- function() {
  readRDS(system.file("extdata", "meseta_iberica_inputs.rds", package = "multiscape"))
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

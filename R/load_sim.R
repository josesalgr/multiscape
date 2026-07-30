#' Example feature raster
#'
#' Load the example feature raster shipped with the package.
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
#'   \item{\code{effects}}{Action effects by action and feature.}
#' }
#'
#' @examples
#' toy <- load_sim_multiaction()
#' names(toy)
#' toy$planning_units
#'
#' @export
load_sim_multiaction <- function() {
  e <- new.env(parent = emptyenv())
  utils::data("sim_multiaction", package = "multiscape", envir = e)
  e$sim_multiaction
}

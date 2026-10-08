#' Simulated planning units
#'
#' Historical ecosystem-services planning units: 30,496 spatial cells.
#' These are distinct from `sim_pu`. Prefer [load_ecosystem_services()]
#' to load the matching planning units and feature raster.
#'
#' @format An object of class `sf`.
#' @usage data(sim_pu_sf)
"sim_pu_sf"

#' Simulated planning units
#'
#' Historical Meseta-related planning units: 11,109 spatial cells with unit
#' cost 1. These are distinct from `sim_pu_sf` and are not the complete
#' Meseta tutorial inputs. Prefer [load_meseta()] for that tutorial.
#'
#' @format An object of class `sf`.
#' @usage data(sim_pu)
"sim_pu"

#' Simulated features
#'
#' Historical Meseta-related catalogue of 155 features, retained for
#' compatibility. These do not belong to the compact simulated example.
#' Prefer [load_meseta()] for the complete tutorial inputs.
#'
#' @format A data frame with feature identifiers and names.
#' @usage data(sim_features)
"sim_features"

#' Simulated feature distribution
#'
#' Historical Meseta-related distribution with 348,021 rows, paired with
#' `sim_pu` and `sim_features`. It is not the zero credited comparison
#' reference used in the introductory tutorial. Prefer [load_meseta()].
#'
#' @format A data frame linking planning units and features with an `amount` column.
#' @usage data(sim_dist_features)
"sim_dist_features"

#' Simulated spatial multi-action planning inputs
#'
#' Prefer [load_sim_multiaction()] as the entry point to this dataset.
#' Direct `data()` access remains available for compatibility.
#'
#' A compact example dataset containing all inputs needed to build a
#' multi-objective spatial planning problem with protection and restoration as
#' mutually exclusive candidate actions.
#'
#' @format A named list with seven components:
#' \describe{
#'   \item{\code{planning_units}}{An \code{sf} object with 64 square planning units.}
#'   \item{\code{features}}{A data frame with two feature identifiers and names.}
#'   \item{\code{dist_features}}{A data frame of feature amounts by planning unit.}
#'   \item{\code{actions}}{A data frame describing protection and restoration.}
#'   \item{\code{action_costs}}{A data frame of spatially varying action costs.}
#'   \item{\code{effect_assumptions}}{Relative changes by action and feature,
#'   ready to pass to \code{\link{add_effects}}.}
#'   \item{\code{effects}}{Explicit signed changes in the historical \code{delta}
#'   column, retained for compatibility. New examples use \code{effect_assumptions}.}
#' }
#' @usage data(sim_multiaction)
"sim_multiaction"


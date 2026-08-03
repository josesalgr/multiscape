#' Simulated planning units
#'
#' Example planning units as an `sf` object for package examples and tests.
#'
#' @format An object of class `sf`.
#' @usage data(sim_pu_sf)
"sim_pu_sf"

#' Simulated planning units
#'
#' Example planning units as an `sf` object for package examples and tests.
#'
#' @format An object of class `sf`.
#' @usage data(sim_pu)
"sim_pu"

#' Simulated features
#'
#' Example feature table for package examples and tests.
#'
#' @format A data frame with feature identifiers and names.
#' @usage data(sim_features)
"sim_features"

#' Simulated feature distribution
#'
#' Example distribution of feature amounts across planning units.
#'
#' @format A data frame linking planning units and features with an `amount` column.
#' @usage data(sim_dist_features)
"sim_dist_features"

#' Simulated spatial multi-action planning inputs
#'
#' A compact example dataset containing all inputs needed to build a
#' multi-objective spatial planning problem with protection and restoration as
#' mutually exclusive candidate actions.
#'
#' @format A named list with six components:
#' \describe{
#'   \item{\code{planning_units}}{An \code{sf} object with 64 square planning units.}
#'   \item{\code{features}}{A data frame with two feature identifiers and names.}
#'   \item{\code{dist_features}}{A data frame of feature amounts by planning unit.}
#'   \item{\code{actions}}{A data frame describing protection and restoration.}
#'   \item{\code{action_costs}}{A data frame of spatially varying action costs.}
#'   \item{\code{effects}}{A data frame of action-specific feature multipliers.}
#' }
#' @usage data(sim_multiaction)
"sim_multiaction"


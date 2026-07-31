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

#' MaPP Rwanda reserve-planning example
#'
#' Derived inputs from the Rwanda training exercise developed for the Marxan
#' Planning Platform (MaPP). The object contains planning units, a Human
#' Modification Index-based cost, existing protected areas, nine mammal
#' distributions, four terrestrial ecoregions, and tables that encode a single
#' reserve action for use in package examples.
#'
#' The training exercise is fictional and uses an arbitrary subset of
#' biodiversity features. It is provided for methodological illustration only;
#' solutions generated from these data should not be interpreted as
#' conservation recommendations for Rwanda.
#'
#' @format A named list with six components:
#' \describe{
#'   \item{planning_units}{An `sf` object with planning-unit identifiers,
#'   costs, areas, protected-area coverage, and a logical `protected` field.}
#'   \item{features}{A data frame describing nine species and four ecoregions.}
#'   \item{feature_distribution}{A data frame containing feature amounts,
#'   measured as intersection area in square metres, by planning unit.}
#'   \item{actions}{A one-row data frame defining the `reserve` action.}
#'   \item{effects}{A feature-level table assigning the baseline amount to the
#'   reserve action.}
#'   \item{metadata}{Tutorial citation, target, protected-area threshold, and
#'   interpretation notes.}
#' }
#'
#' @source TNC (2024). *The Marxan Planning Platform: Tutorial (Rwanda)*.
#' Global Science, The Nature Conservancy, Arlington, Virginia, USA.
#' \url{https://marxanplanning.org}
#'
#' Mammal distributions: Rondinini et al. (2011),
#' \doi{10.1098/rstb.2011.0113}. Terrestrial ecoregions: Olson et al. (2001),
#' \doi{10.1641/0006-3568(2001)051[0933:TEOTWA]2.0.CO;2}. Human modification:
#' Kennedy et al. (2019), \doi{10.1111/gcb.14549}, and Theobald et al. (2020),
#' \doi{10.5194/essd-12-1953-2020}.
#'
#' @usage data(rwanda_reserve)
#' @keywords datasets
"rwanda_reserve"

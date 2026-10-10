#' @include internal.R
NULL

.pa_cardinality_ids <- function(values, what) {
  if (is.factor(values)) values <- as.character(values)
  if (!is.null(dim(values)) || is.object(values) ||
      !(is.character(values) || is.numeric(values)) || !length(values)) {
    stop(what, " must be a non-empty vector of identifiers.", call. = FALSE)
  }
  if (anyNA(values) || (is.numeric(values) && any(!is.finite(values)))) {
    stop(what, " cannot contain missing or non-finite identifiers.", call. = FALSE)
  }
  values <- as.character(values)
  if (any(!nzchar(trimws(values)))) {
    stop(what, " cannot contain empty identifiers.", call. = FALSE)
  }
  sort(unique(values), method = "radix")
}

.pa_cardinality_count <- function(count) {
  if (!is.numeric(count) || is.object(count) || length(count) != 1L ||
      !is.null(dim(count)) || is.na(count) || !is.finite(count) ||
      count < 0 || count != floor(count) || count > .Machine$integer.max) {
    stop("`count` must be a single finite, non-negative integer.", call. = FALSE)
  }
  as.integer(count)
}

.pa_cardinality_available_pairs <- function(da) {
  keep <- rep(TRUE, nrow(da))
  if ("status" %in% names(da)) keep <- keep & !is.na(da$status) & da$status != 3L
  if ("cost" %in% names(da)) keep <- keep & is.finite(da$cost)
  da[keep, , drop = FALSE]
}

.pa_validate_action_cardinality_specs <- function(specs, pu, actions, da) {
  if (is.null(specs)) return(invisible(NULL))
  required <- c("type", "count", "sense", "actions", "pu", "name")
  if (!is.data.frame(specs) || !all(required %in% names(specs)) ||
      !is.list(specs$pu) || !is.list(specs$actions)) {
    stop("Stored action-cardinality constraints are malformed.", call. = FALSE)
  }
  available <- .pa_cardinality_available_pairs(da)
  for (k in seq_len(nrow(specs))) {
    count <- .pa_cardinality_count(specs$count[k])
    if (!identical(specs$type[k], "action_cardinality") ||
        is.na(specs$sense[k]) || !specs$sense[k] %in% c("min", "max", "equal") ||
        is.na(specs$name[k]) || !nzchar(trimws(specs$name[k]))) {
      stop("Stored action-cardinality constraint has invalid type, sense, or name.",
           call. = FALSE)
    }
    pu_ids <- specs$pu[[k]]
    if (!length(pu_ids) || anyNA(pu_ids) || any(!pu_ids %in% pu$id)) {
      stop("Action-cardinality constraint '", specs$name[k],
           "' contains unknown PU ids.", call. = FALSE)
    }
    action_ids <- specs$actions[[k]]
    if (!is.null(action_ids) &&
        (!length(action_ids) || anyNA(action_ids) || any(!action_ids %in% actions$id))) {
      stop("Action-cardinality constraint '", specs$name[k],
           "' contains unknown action ids.", call. = FALSE)
    }
    if (specs$sense[k] %in% c("min", "equal") && count > 0L) {
      pairs <- available[available$pu %in% pu_ids, , drop = FALSE]
      if (!is.null(action_ids)) pairs <- pairs[pairs$action %in% action_ids, , drop = FALSE]
      n_available <- tabulate(match(pairs$pu, pu_ids), nbins = length(pu_ids))
      bad <- pu_ids[n_available < count]
      if (length(bad)) {
        stop("Action-cardinality constraint '", specs$name[k],
             "' requires more actions than available in PU id(s): ",
             paste(bad, collapse = ", "), ".", call. = FALSE)
      }
    }
  }
  invisible(specs)
}

.pa_action_cardinality_covered_pu <- function(specs) {
  if (is.null(specs) || !nrow(specs)) return(integer())
  total_upper <- vapply(specs$actions, is.null, logical(1)) &
    specs$sense %in% c("max", "equal")
  unique(as.integer(unlist(specs$pu[total_upper], use.names = FALSE)))
}

# A conservative upper bound, used only to protect the unfinished ecological
# aggregation path. Cardinality constraints themselves are compiled exactly.
.pa_action_cardinality_upper_bounds <- function(x) {
  da <- x$data$dist_actions_model
  specs <- x$data$constraints$action_cardinality
  pu_ids <- x$data$pu$id
  upper <- tabulate(match(da$pu, pu_ids), nbins = length(pu_ids))
  covered <- .pa_action_cardinality_covered_pu(specs)
  upper[!pu_ids %in% covered] <- pmin(upper[!pu_ids %in% covered], 1L)
  if (!is.null(specs)) {
    # A zero upper bound removes these decisions from every other count.
    allowed <- rep(TRUE, nrow(da))
    for (k in which(specs$sense %in% c("max", "equal") & specs$count == 0L)) {
      in_scope <- da$pu %in% specs$pu[[k]]
      if (!is.null(specs$actions[[k]])) {
        in_scope <- in_scope & da$action %in% specs$actions[[k]]
      }
      allowed[in_scope] <- FALSE
    }
    da <- da[allowed, , drop = FALSE]
    upper <- pmin(upper, tabulate(match(da$pu, pu_ids), nbins = length(pu_ids)))
    for (k in which(specs$sense %in% c("max", "equal"))) {
      ids <- specs$pu[[k]]
      scope <- match(ids, pu_ids)
      outside <- integer(length(ids))
      if (!is.null(specs$actions[[k]])) {
        outside <- tabulate(match(da$pu[!da$action %in% specs$actions[[k]]], ids),
                            nbins = length(ids))
      }
      upper[scope] <- pmin(upper[scope], as.numeric(specs$count[k]) + outside)
    }
  }
  if ("locked_out" %in% names(x$data$pu)) {
    upper[!is.na(x$data$pu$locked_out) & x$data$pu$locked_out] <- 0L
  }
  stats::setNames(upper, pu_ids)
}

.pa_validate_action_cardinality_model <- function(x) {
  specs <- x$data$constraints$action_cardinality
  if (is.null(specs)) return(x)
  .pa_validate_action_cardinality_specs(
    specs, x$data$pu, x$data$actions, x$data$dist_actions_model
  )
  x
}

.pa_apply_action_cardinality_if_present <- function(x) {
  specs <- x$data$constraints$action_cardinality
  if (is.null(specs) || !nrow(specs)) return(x)
  x <- .pa_refresh_model_snapshot(x)
  x0 <- as.integer(x$data$model_list$x_offset)
  da <- x$data$dist_actions_model
  rows_by_pu <- split(seq_len(nrow(da)), da$pu)
  registry <- vector("list", nrow(specs))
  for (k in seq_len(nrow(specs))) {
    action_ids <- specs$actions[[k]]
    rows <- list()
    for (id in specs$pu[[k]]) {
      indices <- rows_by_pu[[as.character(id)]]
      if (!is.null(action_ids)) indices <- indices[da$action[indices] %in% action_ids]
      # Empty sums satisfy zero lower/equality bounds and all upper bounds.
      # Impossible positive lower/equality bounds have already been rejected.
      if (!length(indices)) next
      rows[[as.character(id)]] <- rcpp_add_linear_constraint(
        x$data$model_ptr,
        j0 = x0 + as.integer(da$internal_row[indices]) - 1L,
        x = rep(1, length(indices)),
        sense = switch(specs$sense[k], min = ">=", max = "<=", equal = "=="),
        rhs = specs$count[k],
        name = paste0(specs$name[k], "_pu_", id),
        block_name = "action_cardinality",
        tag = specs$name[k]
      )
    }
    registry[[k]] <- list(name = specs$name[k], n_constraints_added = length(rows), rows = rows)
  }
  names(registry) <- specs$name
  x$data$model_registry$cons$action_cardinality <- registry
  x
}

#' Constrain the number of actions selected per planning unit
#'
#' @description
#' Set a minimum, maximum, or exact number of management actions that can be
#' selected in each planning unit. Rules can apply to all units, selected units,
#' all actions, or a specified subset of actions.
#'
#' @details
#' \strong{How action cardinality works}
#'
#' A cardinality constraint limits the number of individual actions selected
#' \emph{within each planning unit}. For example, \code{count = 2} and
#' \code{sense = "max"} allow zero, one, or two actions per unit, whereas
#' \code{sense = "equal"} requires exactly two. The available senses are:
#' \itemize{
#'   \item \code{"max"}: select at most \code{count} actions.
#'   \item \code{"min"}: select at least \code{count} actions.
#'   \item \code{"equal"}: select exactly \code{count} actions.
#' }
#' The limit is evaluated separately for every unit covered by \code{pu};
#' it is not a total number of actions across the study area.
#'
#' \strong{Default and overlapping rules}
#'
#' By default, at most one action can be selected per planning unit. To allow
#' concurrent actions, specify a total maximum or exact-count rule with
#' \code{actions = NULL}. That rule replaces the default one-action limit only
#' in the planning units it covers. A minimum rule or a rule restricted to
#' an action subset does not remove the default limit.
#'
#' For example, to require at least two actions in a unit, first allow at
#' least two with a total maximum, then add the minimum. Rules from different
#' calls are enforced together; later rules do not overwrite earlier ones.
#' Conflicting rules can make the problem infeasible.
#'
#' \strong{Restricting the scope}
#'
#' Supply \code{pu} to restrict a rule to particular planning units and
#' \code{actions} to count only specified actions. For example, a minimum
#' of one action from \code{c("restore", "control")} requires at least one
#' of those actions in every covered unit. Actions excluded by the subset
#' are not counted towards that particular rule.
#'
#' Cardinality counts individual selected actions, not the action sets
#' registered with \code{add_action_sets()}. Registered sets describe joint
#' effects when their member actions are selected; they are not additional
#' selectable actions.
#'
#' \strong{Feasibility and stored rules}
#'
#' Only available planning-unit/action pairs can be selected. A positive
#' minimum or exact count larger than the number of available actions in a
#' covered unit is rejected. Conflicts with other constraints may still be
#' detected only when the problem is solved. Explicit rules are stored in
#' \code{x$data$constraints$action_cardinality} and do not themselves
#' select actions or run an optimisation solver.
#'
#' @param x A \code{Problem} object with actions registered using
#'   \code{add_actions()}.
#' @param count A single finite, non-negative integer giving the number of
#'   selected individual actions per planning unit.
#' @param sense One of \code{"min"}, \code{"max"}, or \code{"equal"}.
#' @param actions Optional subset of action identifiers or existing
#'   \code{actions$action_set} classification labels. \code{NULL} (default)
#'   counts all actions. Identifiers registered through \code{add_action_sets()}
#'   cannot be counted directly; use their individual member actions.
#' @param pu Optional vector of planning-unit identifiers. \code{NULL}
#'   (default) applies the rule separately to all planning units.
#' @param name Optional name for the constraint. A unique name is generated
#'   when \code{NULL}.
#'
#' @return An updated \code{Problem} with an additional rule in
#'   \code{x$data$constraints$action_cardinality}. The input problem is
#'   preserved; no optimisation is performed.
#'
#' @examples
#' # EXAMPLE 1: Define the available decisions
#'
#' # Consider three planning units, each with four possible actions.
#' # By default, the model allows at most one action in each unit.
#' # Registering actions does not select any of them.
#'
#' problem <- create_problem(
#'   pu = data.frame(id = c(10L, 20L, 30L), cost = 1),
#'   features = data.frame(id = 1L, name = "woodland"),
#'   dist_features = data.frame(
#'     pu = c(10L, 20L, 30L), feature = 1L, amount = 10
#'   )
#' ) |>
#'   add_actions(
#'     data.frame(id = c("restore", "control", "fence", "monitor")),
#'     cost = 1
#'   )
#'
#' # EXAMPLE 2: Different capacities in different planning units
#'
#' # Allow up to three actions in unit 10 and up to two in unit 20.
#' # Unit 30 retains the default maximum of one action.
#' # A maximum permits fewer actions, including no intervention.
#'
#' capacities <- problem |>
#'   add_constraint_action_cardinality(
#'     count = 3, sense = "max", pu = 10L, name = "capacity_10"
#'   ) |>
#'   add_constraint_action_cardinality(
#'     count = 2, sense = "max", pu = 20L, name = "capacity_20"
#'   )
#'
#' # Inspect the registered constraints, not solved decisions.
#' capacities$data$constraints$action_cardinality[
#'   , c("name", "count", "sense")
#' ]
#'
#' # EXAMPLE 3: Require at least one action from a subset
#'
#' # In units 10 and 20, require restoration or control (or both).
#' # The minimum applies separately to each unit, and only these
#' # two actions count towards the requirement. The previously
#' # defined total capacities remain in force.
#'
#' required <- capacities |>
#'   add_constraint_action_cardinality(
#'     count = 1, sense = "min",
#'     actions = c("restore", "control"),
#'     pu = c(10L, 20L), name = "management_required"
#'   )
#'
#' # EXAMPLE 4: Require an exact count or prohibit interventions
#'
#' # An exact count of two overrides the default one-action maximum
#' # in unit 10 and requires two distinct actions to be selected.
#'
#' exact <- add_constraint_action_cardinality(
#'   problem, count = 2, sense = "equal", pu = 10L
#' )
#'
#' # A zero maximum prohibits all actions in unit 30.
#' # It does not exclude that unit from the planning region.
#'
#' no_action <- add_constraint_action_cardinality(
#'   problem, count = 0, sense = "max", pu = 30L
#' )
#'
#' # EXAMPLE 5: Map where a more flexible capacity is allowed
#'
#' # Use the bundled 64-unit landscape to impose a hypothetical
#' # policy allowing two concurrent actions in the eastern half.
#' # All other planning units retain the default maximum of one.
#' # No solver is needed to visualise the scope of the rule.
#'
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   sim <- load_sim_multiaction()
#'   spatial_problem <- create_problem(
#'     pu = sim$planning_units,
#'     features = sim$features,
#'     dist_features = sim$dist_features,
#'     cost = "cost"
#'   ) |>
#'     add_actions(sim$actions, cost = sim$action_costs)
#'
#'   # Identify the eastern units using the x-coordinate of their
#'   # polygon centroids. The two-action limit is an upper bound,
#'   # not a requirement to select two actions.
#'   centres <- sf::st_coordinates(
#'     sf::st_centroid(sf::st_geometry(sim$planning_units))
#'   )
#'   east <- centres[, 1] > stats::median(centres[, 1])
#'   eastern_ids <- sim$planning_units$id[east]
#'
#'   spatial_problem <- add_constraint_action_cardinality(
#'     spatial_problem, count = 2, sense = "max", pu = eastern_ids
#'   )
#'
#'   # Display the geographical limits, not selected actions.
#'   capacity_map <- sim$planning_units
#'   capacity_map$max_actions <- ifelse(east, 2L, 1L)
#'   plot(capacity_map["max_actions"], main = "Maximum actions per unit")
#' }
#'
#' @seealso \code{\link{add_actions}}, \code{\link{add_action_sets}},
#'   \code{\link{add_constraint_budget}}
#' @export
add_constraint_action_cardinality <- function(x, count, sense, actions = NULL,
                                              pu = NULL, name = NULL) {
  if (!inherits(x, "Problem")) stop("`x` must be a Problem object.", call. = FALSE)
  acts <- x$data$actions
  da <- x$data$dist_actions
  if (!is.data.frame(acts) || !nrow(acts) || !is.data.frame(da)) {
    stop("No actions available. Run add_actions() first.", call. = FALSE)
  }
  if (missing(count)) stop("`count` must be provided.", call. = FALSE)
  count <- .pa_cardinality_count(count)
  if (missing(sense) || is.null(sense)) {
    stop("`sense` must be explicitly provided: 'min', 'max', or 'equal'.", call. = FALSE)
  }
  sense <- match.arg(sense, c("min", "max", "equal"))
  if (!is.null(name) && (!is.character(name) || length(name) != 1L ||
                         is.na(name) || !nzchar(trimws(name)))) {
    stop("`name` must be NULL or a non-empty character string.", call. = FALSE)
  }
  pu_ids <- x$data$pu$id
  if (!is.null(pu)) {
    ids <- .pa_cardinality_ids(pu, "`pu`")
    bad <- setdiff(ids, as.character(pu_ids))
    if (length(bad)) stop("Unknown PU id(s): ", paste(bad, collapse = ", "), ".", call. = FALSE)
    pu_ids <- pu_ids[as.character(pu_ids) %in% ids]
  }
  pu_ids <- sort(unique(as.integer(pu_ids)))
  action_ids <- NULL
  if (!is.null(actions)) {
    ids <- .pa_cardinality_ids(actions, "`actions`")
    known <- as.character(acts$id)
    if ("action_set" %in% names(acts)) known <- c(known, as.character(acts$action_set))
    bad <- setdiff(ids, known)
    if (length(bad)) {
      stop("Unknown action id(s) or classification labels: ", paste(bad, collapse = ", "),
           ". Use individual members of registered action sets.", call. = FALSE)
    }
    action_ids <- sort(as.character(.pa_resolve_action_subset(x, ids)$id), method = "radix")
  }
  existing <- x$data$constraints$action_cardinality
  .pa_validate_action_cardinality_specs(existing, x$data$pu, acts, da)
  n <- if (is.null(existing)) 0L else nrow(existing)
  if (is.null(name)) {
    i <- n + 1L
    name <- paste0("action_cardinality_", i)
    while (name %in% existing$name) {
      i <- i + 1L
      name <- paste0("action_cardinality_", i)
    }
  }
  for (k in seq_len(n)) {
    if (identical(existing$pu[[k]], pu_ids) &&
        identical(existing$actions[[k]], action_ids) && existing$sense[k] == sense) {
      stop("An action-cardinality constraint already exists for this PU subset, action subset, and sense.",
           call. = FALSE)
    }
  }
  if (name %in% existing$name) {
    stop("Action-cardinality constraint name already registered: ", name, ".", call. = FALSE)
  }
  spec <- data.frame(type = "action_cardinality", count = count, sense = sense,
                     name = name, stringsAsFactors = FALSE)
  spec$actions <- list(action_ids)
  spec$pu <- list(pu_ids)
  specs <- if (n) rbind(existing, spec) else spec
  .pa_validate_action_cardinality_specs(specs, x$data$pu, acts, da)
  out <- .pa_clone_data(x)
  out$data$constraints$action_cardinality <- specs
  out
}

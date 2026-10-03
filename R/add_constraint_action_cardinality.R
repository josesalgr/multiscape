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
  registry <- vector("list", nrow(specs))
  for (k in seq_len(nrow(specs))) {
    action_ids <- specs$actions[[k]]
    rows <- list()
    for (id in specs$pu[[k]]) {
      keep <- da$pu == id
      if (!is.null(action_ids)) keep <- keep & da$action %in% action_ids
      # Empty sums satisfy zero lower/equality bounds and all upper bounds.
      # Impossible positive lower/equality bounds have already been rejected.
      if (!any(keep)) next
      rows[[as.character(id)]] <- rcpp_add_linear_constraint(
        x$data$model_ptr,
        j0 = x0 + as.integer(da$internal_row[keep]) - 1L,
        x = rep(1, sum(keep)),
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

#' Constrain the number of actions in each planning unit
#'
#' @description
#' Add a minimum, maximum, or exact count of selected individual actions in
#' each of the specified planning units. Multiple rules can be added across
#' calls, including different limits for different units or action subsets.
#'
#' @details
#' The constraint is applied separately to every unit in `pu`, rather than
#' to their combined count. For each unit it constrains the sum of binary
#' action-selection variables, using `>=`, `<=`, or `=` for `sense = "min"`,
#' `"max"`, or `"equal"`, respectively. There is no equality tolerance because
#' the count is an integer. Counts refer to individual actions; registering
#' an action set does not add another counted decision.
#'
#' By default, at most one action can be selected in each unit. An explicit
#' rule with `actions = NULL` and `sense = "max"` or `"equal"` replaces that
#' implicit limit in the units it covers. A minimum alone or a rule restricted
#' to an action subset does not remove the implicit limit. To require at least
#' two actions, also supply a total upper bound allowing two or more.
#'
#' All explicit rules are enforced together, independently of call order.
#' Overlapping maxima use the stricter bound; a later rule does not overwrite
#' an earlier one. Duplicate combinations of planning-unit subset, action
#' subset, and sense are rejected. Names must also be unique within these
#' constraints. Contradictions involving multiple rules, budgets, or locks
#' can still make the model infeasible; the solver reports such infeasibility.
#'
#' Only available planning-unit/action pairs are counted. Locked-out actions
#' and pairs with invalid costs are excluded as in model compilation. A
#' positive minimum or equality exceeding available actions in any scoped
#' unit is rejected. An empty sum is zero, so maxima and zero bounds remain
#' valid even in units without available actions.
#'
#' Concurrent actions support costs, profits, ecological objectives, and targets.
#' Individual effects are additive unless a joint total is supplied through a
#' registered action set. Benefit maximizes signed change; loss is split after
#' aggregation within each unit and feature. Targets count the reference once
#' for selected units in their action scope.
#'
#' @param x A `Problem` object with registered actions.
#' @param count A single finite, non-negative integer.
#' @param sense Required string: `"min"`, `"max"`, or `"equal"`.
#' @param actions Optional action subset, using the standard parser for action
#'   ids or existing `actions$action_set` classification labels. `NULL` counts
#'   all actions. Identifiers defined by [add_action_sets()] are not selectable
#'   actions and are not accepted here; supply their individual members.
#' @param pu Optional vector of external planning-unit ids. `NULL` applies
#'   the rule to all currently registered units.
#' @param name Optional non-empty string used to label the constraint. If
#'   `NULL`, a name is generated. This label is independent of objective aliases.
#'
#' @return A new `Problem` with the rule appended to
#'   `x$data$constraints$action_cardinality`. Its compiled model is invalidated;
#'   the input problem is preserved.
#'
#' @examples
#' problem <- create_problem(
#'   pu = data.frame(id = c(10L, 20L, 30L), cost = 1),
#'   features = data.frame(id = 1L, name = "woodland"),
#'   dist_features = data.frame(pu = c(10L, 20L, 30L), feature = 1L, amount = 10)
#' ) |>
#'   add_actions(data.frame(id = c("restore", "control", "fence", "monitor")), cost = 1)
#'
#' # Different capacities: four in unit 10, two in unit 20, default one in 30.
#' capacities <- problem |>
#'   add_constraint_action_cardinality(4, "max", pu = 10L, name = "capacity_10") |>
#'   add_constraint_action_cardinality(2, "max", pu = 20L, name = "capacity_20")
#'
#' # At least one action from this subset in each of those units.
#' required <- capacities |>
#'   add_constraint_action_cardinality(
#'     1, "min", actions = c("restore", "control"), pu = c(10L, 20L)
#'   )
#'
#' # An exact total count also replaces the implicit one-action maximum.
#' exact <- problem |>
#'   add_constraint_action_cardinality(2, "equal", pu = 10L)
#' exact$data$constraints$action_cardinality
#'
#' @seealso [add_actions()], [add_action_sets()], [add_constraint_budget()]
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

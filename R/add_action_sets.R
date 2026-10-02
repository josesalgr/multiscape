#' @include internal.R
NULL

.pa_empty_action_sets <- function() {
  data.frame(set = character(), action = character(), stringsAsFactors = FALSE)
}

.pa_action_set_identifiers <- function(values, what, numeric_ids = FALSE) {
  if (is.factor(values)) values <- as.character(values)
  if (!is.null(dim(values)) || is.object(values) ||
      (!is.character(values) && !(numeric_ids && is.numeric(values)))) {
    stop(what, " must contain identifiers as strings",
         if (numeric_ids) " or numbers" else "", ".", call. = FALSE)
  }
  if (is.numeric(values) && any(!is.finite(values))) {
    stop(what, " cannot contain missing or non-finite identifiers.", call. = FALSE)
  }
  values <- as.character(values)
  if (anyNA(values) || any(!nzchar(trimws(values)))) {
    stop(what, " cannot contain NA, empty, or whitespace-only identifiers.",
         call. = FALSE)
  }
  values
}

.pa_validate_action_sets <- function(sets, actions) {
  if (!is.data.frame(sets) || !all(c("set", "action") %in% names(sets))) {
    stop("`sets` must have columns 'set' and 'action'.", call. = FALSE)
  }
  if (anyDuplicated(names(sets))) {
    stop("`sets` cannot have duplicated column names.", call. = FALSE)
  }
  out <- data.frame(
    set = .pa_action_set_identifiers(sets$set, "`sets$set`"),
    action = .pa_action_set_identifiers(sets$action, "`sets$action`", TRUE),
    stringsAsFactors = FALSE
  )
  if (!nrow(out)) return(out)
  if (!is.data.frame(actions) || !nrow(actions) || !("id" %in% names(actions))) {
    stop("No actions available. Run add_actions() before add_action_sets().",
         call. = FALSE)
  }
  if (anyDuplicated(out)) {
    stop("`sets` contains duplicated (set, action) memberships.", call. = FALSE)
  }
  reserved <- as.character(actions$id)
  if ("name" %in% names(actions)) reserved <- c(reserved, as.character(actions$name))
  if ("action_set" %in% names(actions)) {
    reserved <- c(reserved, as.character(actions$action_set))
  }
  collisions <- intersect(unique(out$set), reserved)
  if (length(collisions)) {
    stop("Action set identifiers conflict with action ids, action names, or ",
         "existing action_set labels: ", paste(collisions, collapse = ", "), ".",
         call. = FALSE)
  }
  unknown <- setdiff(unique(out$action), as.character(actions$id))
  if (length(unknown)) {
    stop("Unknown action id(s) in `sets`: ", paste(unknown, collapse = ", "),
         ". Members must be registered atomic action ids; nested sets are not supported.",
         call. = FALSE)
  }
  sizes <- table(out$set)
  too_small <- names(sizes)[sizes < 2L]
  if (length(too_small)) {
    stop("Each action set must contain at least two distinct actions: ",
         paste(too_small, collapse = ", "), ".", call. = FALSE)
  }
  out <- out[order(out$set, out$action, method = "radix"), , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Register sets of management actions
#'
#' @description
#' Define named combinations of existing actions. An action can belong to more
#' than one set. Sets are stored separately from the individual action catalog.
#'
#' @details
#' Run [add_actions()] first. Supply either a named list of action-id vectors or
#' a long table with one row per membership and columns `set` and `action`.
#' Additional table columns are ignored. Each set must contain at least two
#' distinct registered actions; duplicate memberships and nested sets are
#' rejected. Members are matched by action id, not by their display name.
#'
#' Set identifiers cannot coincide with action ids, action display names, or
#' existing labels in `actions$action_set`. The latter column remains an
#' independent, backward-compatible action classification.
#'
#' Repeated calls add new sets. Reusing a registered set identifier is an error,
#' including attempts to extend or redefine its membership. Definitions are
#' returned in a consistent order by [get_action_sets()].
#'
#' Registering a set does not create a selectable action, change feasible
#' planning-unit/action pairs, require its members to be selected together, or
#' add an interaction effect. It also does not enable simultaneous actions:
#' the default maximum of one selected action per planning unit still applies
#' unless changed with [add_constraint_action_cardinality()].
#' Sets may be registered even if their members have no common feasible unit.
#' In this release they are definitions only and cannot yet be supplied as
#' action identifiers to effect, objective, or constraint functions.
#'
#' @param x A `Problem` object with registered actions.
#' @param sets A non-empty named list of action-id vectors, or a non-empty
#'   `data.frame` with columns `set` and `action`. Set identifiers are strings;
#'   members can be strings or numeric action ids. Factors are accepted.
#'
#' @return A new `Problem` object containing the definitions. The input object
#'   is not modified. Any previously compiled model is invalidated, following
#'   the usual problem-construction workflow.
#'
#' @examples
#' problem <- create_problem(
#'   pu = data.frame(id = 1:2, cost = c(1, 2)),
#'   features = data.frame(id = 1L, name = "woodland"),
#'   dist_features = data.frame(
#'     pu = 1:2, feature = 1L, amount = c(10, 20)
#'   )
#' ) |>
#'   add_actions(
#'     actions = data.frame(id = c("restore", "control", "fence")),
#'     cost = 1
#'   )
#'
#' # An action may belong to several sets.
#' list_problem <- problem |>
#'   add_action_sets(list(
#'     restore_control = c("restore", "control"),
#'     restore_fence = c("restore", "fence")
#'   ))
#' get_action_sets(list_problem)
#'
#' # Equivalent definitions in long-table format.
#' memberships <- data.frame(
#'   set = c("restore_control", "restore_control", "restore_fence", "restore_fence"),
#'   action = c("restore", "control", "restore", "fence")
#' )
#' table_problem <- add_action_sets(problem, memberships)
#' identical(get_action_sets(list_problem), get_action_sets(table_problem))
#'
#' # Add another set without changing existing definitions.
#' table_problem <- table_problem |>
#'   add_action_sets(list(control_fence = c("control", "fence")))
#' get_action_sets(table_problem)
#'
#' @seealso [add_actions()], [get_action_sets()], [add_constraint_action_cardinality()]
#' @export
add_action_sets <- function(x, sets) {
  if (!inherits(x, "Problem")) {
    stop("`x` must be a Problem object.", call. = FALSE)
  }
  actions <- x$data$actions
  if (!is.data.frame(actions) || !nrow(actions)) {
    stop("No actions available. Run add_actions() before add_action_sets().",
         call. = FALSE)
  }
  if (is.data.frame(sets)) {
    if (!nrow(sets)) stop("`sets` must be non-empty.", call. = FALSE)
    memberships <- sets
  } else if (is.list(sets)) {
    if (!length(sets)) stop("`sets` must be non-empty.", call. = FALSE)
    if (is.null(names(sets))) {
      stop("`sets` must be a named list.", call. = FALSE)
    }
    set_ids <- .pa_action_set_identifiers(names(sets), "Names of `sets`")
    if (anyDuplicated(set_ids)) {
      stop("Names of `sets` must be unique.", call. = FALSE)
    }
    rows <- lapply(seq_along(sets), function(i) {
      members <- .pa_action_set_identifiers(
        sets[[i]], paste0("Members of set '", set_ids[i], "'"), TRUE
      )
      if (length(members) < 2L) {
        stop("Each action set must contain at least two distinct actions: ",
             set_ids[i], ".", call. = FALSE)
      }
      data.frame(set = set_ids[i], action = members, stringsAsFactors = FALSE)
    })
    memberships <- do.call(rbind, rows)
  } else {
    stop("`sets` must be a named list or a data.frame with columns 'set' and 'action'.",
         call. = FALSE)
  }
  memberships <- .pa_validate_action_sets(memberships, actions)
  existing <- x$data$action_sets
  if (!is.null(existing)) {
    existing <- .pa_validate_action_sets(existing, actions)
    overlap <- intersect(unique(existing$set), unique(memberships$set))
    if (length(overlap)) {
      stop("Action set identifier(s) already registered: ",
           paste(overlap, collapse = ", "), ". Existing sets cannot be redefined.",
           call. = FALSE)
    }
    memberships <- .pa_validate_action_sets(rbind(existing, memberships), actions)
  }
  out <- .pa_clone_data(x)
  out$data$action_sets <- memberships
  out
}

#' Inspect registered action sets
#'
#' @description
#' Return the definitions registered by [add_action_sets()] in long format.
#' This function inspects a planning problem, not selected actions in a solution.
#'
#' @param x A `Problem` object.
#'
#' @return A `data.frame` with character columns `set` and `action`, sorted by
#'   set and action id. If no sets are registered, a zero-row table with the
#'   same columns is returned. Internal identifiers are not exposed.
#'
#' @examples
#' problem <- create_problem(
#'   pu = data.frame(id = 1:2, cost = 1),
#'   features = data.frame(id = 1L, name = "woodland"),
#'   dist_features = data.frame(pu = 1:2, feature = 1L, amount = 10)
#' ) |>
#'   add_actions(data.frame(id = c("restore", "control")))
#'
#' get_action_sets(problem)
#' problem <- add_action_sets(
#'   problem, list(restore_control = c("restore", "control"))
#' )
#' get_action_sets(problem)
#'
#' @seealso [add_action_sets()], [get_actions()]
#' @export
get_action_sets <- function(x) {
  if (!inherits(x, "Problem")) {
    stop("`x` must be a Problem object.", call. = FALSE)
  }
  sets <- x$data$action_sets
  if (is.null(sets)) return(.pa_empty_action_sets())
  .pa_validate_action_sets(sets, x$data$actions)
}

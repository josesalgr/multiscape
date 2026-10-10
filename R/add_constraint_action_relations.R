#' @include internal.R
NULL

.pa_action_relation_actions <- function(x, values, what) {
  ids <- .pa_cardinality_ids(values, what)
  acts <- x$data$actions
  known <- as.character(acts$id)
  if ("action_set" %in% names(acts)) known <- c(known, as.character(acts$action_set))
  bad <- setdiff(ids, known)
  if (length(bad)) {
    stop("Unknown action id(s) or classification labels in ", what, ": ",
         paste(bad, collapse = ", "),
         ". Use individual members of registered action sets.", call. = FALSE)
  }
  sort(unique(as.character(.pa_resolve_action_subset(x, ids)$id)), method = "radix")
}

.pa_validate_action_relations_specs <- function(specs, pu, actions) {
  if (is.null(specs)) return(invisible(NULL))
  required <- c("type", "sense", "name", "actions", "requires", "pu")
  if (!is.data.frame(specs) || !all(required %in% names(specs)) ||
      !is.list(specs$actions) || !is.list(specs$requires) || !is.list(specs$pu)) {
    stop("Stored action relations are malformed.", call. = FALSE)
  }
  if (anyNA(specs$name) || any(!nzchar(trimws(specs$name))) || anyDuplicated(specs$name)) {
    stop("Stored action-relation names must be non-empty and unique.", call. = FALSE)
  }
  for (k in seq_len(nrow(specs))) {
    type <- specs$type[k]
    if (is.na(type) || !type %in% c("requires", "excludes", "together")) {
      stop("Stored action relation has an invalid type.", call. = FALSE)
    }
    members <- specs$actions[[k]]
    ids <- specs$pu[[k]]
    if (!is.character(members) || !length(members) || anyNA(members) ||
        anyDuplicated(members) || any(!members %in% actions$id)) {
      stop("Action relation '", specs$name[k], "' contains invalid or unknown action ids.", call. = FALSE)
    }
    if (!length(ids) || anyNA(ids) || anyDuplicated(ids) || any(!ids %in% pu$id)) {
      stop("Action relation '", specs$name[k], "' contains invalid or unknown PU ids.", call. = FALSE)
    }
    targets <- specs$requires[[k]]
    if (type == "requires") {
      if (is.na(specs$sense[k]) || !specs$sense[k] %in% c("all", "any") ||
          !is.character(targets) || !length(targets) || anyNA(targets) ||
          anyDuplicated(targets) || any(!targets %in% actions$id)) {
        stop("Stored requires relation has invalid sense or required action ids.", call. = FALSE)
      }
      if (length(intersect(members, targets))) {
        stop("Triggering and required actions must be disjoint.", call. = FALSE)
      }
    } else if (length(members) < 2L || !is.null(targets) || !is.na(specs$sense[k])) {
      stop("Excludes/together relations require at least two actions and no requires/sense specification.",
           call. = FALSE)
    }
  }
  invisible(specs)
}

.pa_add_action_relation <- function(x, type, actions, requires = NULL, sense = NA_character_,
                                    pu = NULL, name = NULL) {
  if (!inherits(x, "Problem")) stop("`x` must be a Problem object.", call. = FALSE)
  if (!is.data.frame(x$data$actions) || !nrow(x$data$actions) ||
      !is.data.frame(x$data$dist_actions)) {
    stop("No actions available. Run add_actions() first.", call. = FALSE)
  }
  members <- .pa_action_relation_actions(x, actions, "`actions`")
  targets <- if (type == "requires") .pa_action_relation_actions(x, requires, "`requires`") else NULL
  if (type == "requires") {
    if (length(intersect(members, targets))) {
      stop("Triggering and required actions must be disjoint.", call. = FALSE)
    }
    # All and any are the same relation when there is only one required action.
    if (length(targets) == 1L) sense <- "all"
  } else if (length(members) < 2L) {
    stop("`actions` must resolve to at least two distinct actions.", call. = FALSE)
  }
  pu_ids <- x$data$pu$id
  if (!is.null(pu)) {
    ids <- .pa_cardinality_ids(pu, "`pu`")
    bad <- setdiff(ids, as.character(pu_ids))
    if (length(bad)) stop("Unknown PU id(s): ", paste(bad, collapse = ", "), ".", call. = FALSE)
    pu_ids <- pu_ids[as.character(pu_ids) %in% ids]
  }
  pu_ids <- sort(unique(as.integer(pu_ids)))
  if (!is.null(name) && (!is.character(name) || length(name) != 1L || is.na(name) ||
                         !nzchar(trimws(name)))) {
    stop("`name` must be NULL or a non-empty character string.", call. = FALSE)
  }
  existing <- x$data$constraints$action_relations
  .pa_validate_action_relations_specs(existing, x$data$pu, x$data$actions)
  n <- if (is.null(existing)) 0L else nrow(existing)
  for (k in seq_len(n)) {
    if (existing$type[k] == type && identical(existing$actions[[k]], members) &&
        identical(existing$requires[[k]], targets) && identical(existing$sense[k], sense) &&
        identical(existing$pu[[k]], pu_ids)) {
      stop("An action relation already exists for this type, action scope, requirement, and PU scope.",
           call. = FALSE)
    }
  }
  if (is.null(name)) {
    i <- n + 1L
    name <- paste0("action_", type, "_", i)
    while (name %in% existing$name) {
      i <- i + 1L
      name <- paste0("action_", type, "_", i)
    }
  }
  if (name %in% existing$name) {
    stop("Action-relation name already registered: ", name, ".", call. = FALSE)
  }
  spec <- data.frame(type = type, sense = sense, name = name, stringsAsFactors = FALSE)
  spec$actions <- list(members)
  spec$requires <- list(targets)
  spec$pu <- list(pu_ids)
  specs <- if (n) rbind(existing, spec) else spec
  .pa_validate_action_relations_specs(specs, x$data$pu, x$data$actions)
  out <- .pa_clone_data(x)
  out$data$constraints$action_relations <- specs
  out
}

.pa_apply_action_relations_if_present <- function(x) {
  specs <- x$data$constraints$action_relations
  if (is.null(specs) || !nrow(specs)) return(x)
  x <- .pa_refresh_model_snapshot(x)
  offset <- as.integer(x$data$model_list$x_offset)
  da <- x$data$dist_actions_model
  rows_by_pu <- split(seq_len(nrow(da)), da$pu)
  registry <- vector("list", nrow(specs))
  for (k in seq_len(nrow(specs))) {
    rows <- list()
    for (id in specs$pu[[k]]) {
      indices <- rows_by_pu[[as.character(id)]]
      if (is.null(indices)) indices <- integer()
      pairs <- da[indices, , drop = FALSE]
      columns <- stats::setNames(offset + as.integer(pairs$internal_row) - 1L, pairs$action)
      members <- specs$actions[[k]]
      available <- intersect(members, names(columns))
      unit_rows <- list()
      add_row <- function(ids, coefficients, sense, rhs) {
        keep <- ids %in% names(columns)
        if (!any(keep)) return(invisible(NULL))
        i <- length(unit_rows) + 1L
        unit_rows[[i]] <<- rcpp_add_linear_constraint(
          x$data$model_ptr, j0 = unname(columns[ids[keep]]), x = coefficients[keep],
          sense = sense, rhs = rhs, name = paste0(specs$name[k], "_pu_", id, "_", i),
          block_name = "action_relations", tag = specs$name[k]
        )
        invisible(NULL)
      }
      if (specs$type[k] == "requires") {
        targets <- specs$requires[[k]]
        for (source in available) {
          if (specs$sense[k] == "all") {
            for (target in targets) add_row(c(source, target), c(1, -1), "<=", 0)
          } else {
            add_row(c(source, targets), c(1, rep(-1, length(targets))), "<=", 0)
          }
        }
      } else if (specs$type[k] == "excludes") {
        if (length(available) >= 2L) add_row(available, rep(1, length(available)), "<=", 1)
      } else if (length(available) < length(members)) {
        # Absent, excluded, or filtered decisions are zero, not forgotten members.
        for (member in available) add_row(member, 1, "==", 0)
      } else {
        for (member in members[-1L]) add_row(c(member, members[1L]), c(1, -1), "==", 0)
      }
      if (length(unit_rows)) rows[[as.character(id)]] <- unit_rows
    }
    registry[[k]] <- list(name = specs$name[k], type = specs$type[k],
                          n_constraints_added = sum(lengths(rows)), rows = rows)
  }
  names(registry) <- specs$name
  x$data$model_registry$cons$action_relations <- registry
  x
}

#' Require companion actions in each planning unit
#'
#' @description
#' Make the selection of one or more actions conditional on selecting
#' companion actions in the same planning unit. With `sense = "all"`, every
#' companion is required; with `sense = "any"`, at least one is required.
#'
#' @details
#' \strong{How the relation works}
#'
#' Suppose restoration is effective only when threat control is also carried
#' out. If restoration is selected, control must also be selected; if
#' restoration is not selected, the relation imposes no requirement. With
#' several triggering actions, each independently activates the requirement.
#'
#' For binary action decisions \eqn{x_{ia}}, requiring all companions gives
#' \eqn{x_{ia} \le x_{ib}} for each required action \eqn{b}. Requiring any
#' companion gives \eqn{x_{ia} \le \sum_b x_{ib}}. When there is only one
#' companion, `"all"` and `"any"` are equivalent.
#'
#' @section Scope and feasibility:
#' Each relation applies separately within each unit specified by `pu`;
#' `pu = NULL` applies it to all registered planning units. Relations do not
#' select actions by themselves or make unavailable actions feasible.
#' **By default, at most one action can be selected per planning unit.**
#' Use [add_constraint_action_cardinality()] when a requires or together rule
#' needs simultaneous selections. Unavailable or locked-out actions are treated
#' as unselected: missing companions may prohibit a trigger, and a missing
#' together member may prohibit the other members. Combined rules, budgets,
#' and locks can also make a model infeasible.
#'
#' Relations do not imply a temporal sequence or dependencies between different
#' planning units. They can be combined with joint effects registered through
#' [add_action_sets()], but defining a joint effect does not itself require
#' actions to be selected together.
#'
#' @section Repeated calls:
#' Distinct rules accumulate and are enforced simultaneously. Duplicate rules
#' with the same type, action groups, sense, and PU scope are rejected; names
#' must be unique across requires, excludes, and together relations. To revise
#' a rule, start from the problem before that rule was added.
#'
#' @param x A `Problem` with actions registered by [add_actions()].
#' @param actions Non-empty vector of triggering action IDs or existing
#'   `actions$action_set` classification labels. For excludes and together,
#'   this is the group of related actions and must resolve to at least two
#'   distinct actions. Identifiers registered through [add_action_sets()] are
#'   not selectable actions; supply their individual members.
#' @param requires Non-empty vector of companion action IDs or existing
#'   classification labels, disjoint from `actions`.
#' @param sense `"all"` (default) requires every companion; `"any"` requires
#'   at least one companion.
#' @param pu Optional external planning-unit IDs. `NULL` applies the rule to
#'   all planning units.
#' @param name Optional unique, non-empty constraint label. If omitted, a
#'   label is generated automatically.
#'
#' @return A new `Problem` with the relation appended to
#'   `x$data$constraints$action_relations`. The input problem is unchanged.
#'
#' @examples
#' # EXAMPLE 1: Create a problem where concurrent actions are possible
#'
#' # Three planning units offer restoration, control, fencing, and monitoring.
#' # Allow up to three actions per unit: the default one-action maximum
#' # would otherwise prevent restoration and its companions being selected.
#'
#' base <- create_problem(
#'   pu = data.frame(id = c(10L, 20L, 30L), cost = 0),
#'   features = data.frame(id = 1L, name = "habitat"),
#'   dist_features = data.frame(
#'     pu = c(10L, 20L, 30L), feature = 1L, amount = 100
#'   )
#' ) |>
#'   add_actions(
#'     data.frame(id = c("restore", "control", "fence", "monitor")),
#'     cost = 1
#'   ) |>
#'   add_constraint_action_cardinality(3, "max")
#'
#' # EXAMPLE 2: Require all companions in a specific unit
#'
#' # In unit 10, restoration must be accompanied by both control and fencing.
#' # This is a conditional requirement: it does not force restoration.
#'
#' required <- add_constraint_action_requires(
#'   base,
#'   actions = "restore",
#'   requires = c("control", "fence"),
#'   sense = "all",
#'   pu = 10L,
#'   name = "restore_with_both"
#' )
#'
#' # EXAMPLE 3: Require at least one alternative companion
#'
#' # In unit 20, either control OR fencing is sufficient for restoration.
#' # These rules have different PU scopes and can coexist.
#'
#' required <- add_constraint_action_requires(
#'   required,
#'   actions = "restore",
#'   requires = c("control", "fence"),
#'   sense = "any",
#'   pu = 20L,
#'   name = "restore_with_either"
#' )
#'
#' # EXAMPLE 4: Multiple independent triggers
#'
#' # In unit 30, choosing either restoration or monitoring requires control.
#' # The triggers need not both be selected.
#'
#' required <- add_constraint_action_requires(
#'   required,
#'   actions = c("restore", "monitor"),
#'   requires = "control",
#'   pu = 30L
#' )
#'
#' # Inspect the three registered rules (not an optimised solution).
#' required$data$constraints$action_relations[, c("type", "sense", "name")]
#'
#' # EXAMPLE 5: Map where a requirement applies (no solver needed)
#'
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   sim <- load_sim_multiaction()
#'
#'   # Apply the restoration-protection requirement to the first 16 cells.
#'   # Both actions may be selected in these cells, so permit cardinality 2.
#'   scoped_pu <- head(sim$planning_units$id, 16)
#'   spatial <- create_problem(
#'     pu = sim$planning_units,
#'     features = sim$features,
#'     dist_features = sim$dist_features,
#'     cost = "cost"
#'   ) |>
#'     add_actions(sim$actions, cost = sim$action_costs) |>
#'     add_constraint_action_cardinality(2, "max", pu = scoped_pu) |>
#'     add_constraint_action_requires(
#'       "restore", "protect", pu = scoped_pu
#'     )
#'
#'   # The map shows the SCOPE of the requirement, not selected actions.
#'   mapped <- sim$planning_units
#'   mapped$requirement <- ifelse(
#'     mapped$id %in% scoped_pu, "Applies", "Does not apply"
#'   )
#'   plot(mapped["requirement"], main = "Restoration requires protection")
#' }
#'
#' @seealso [add_constraint_action_excludes()], [add_constraint_action_together()],
#'   [add_constraint_action_cardinality()], [add_action_sets()]
#' @export
add_constraint_action_requires <- function(x, actions, requires, sense = c("all", "any"),
                                           pu = NULL, name = NULL) {
  if (missing(actions)) stop("`actions` must be provided.", call. = FALSE)
  if (missing(requires)) stop("`requires` must be provided.", call. = FALSE)
  sense <- match.arg(sense)
  .pa_add_action_relation(x, "requires", actions, requires, sense, pu, name)
}

#' Make actions mutually exclusive within each planning unit
#'
#' @description
#' Prevent two or more incompatible actions from being selected together in
#' the same planning unit. At most one action in the specified group may be
#' selected; selecting none is also allowed.
#'
#' @details
#' \strong{How the relation works}
#'
#' Suppose restoration and harvesting are incompatible uses of a site. This
#' relation prevents their simultaneous selection without prohibiting either
#' action individually. With three or more actions, **every pair in the group**
#' is mutually exclusive, not just the complete combination.
#'
#' For every scoped unit, the constraint is
#' \eqn{\sum_{a \in A} x_{ia} \le 1}. Actions outside the group are not
#' restricted by this relation. The rule is most informative when the
#' cardinality settings otherwise permit more than one action per unit.
#'
#' @inheritParams add_constraint_action_requires
#' @param actions At least two action IDs or existing classification labels
#'   that must be mutually exclusive in each scoped planning unit.
#' @inheritSection add_constraint_action_requires Scope and feasibility
#' @inheritSection add_constraint_action_requires Repeated calls
#' @return A new `Problem` with the relation appended. The input problem is
#'   unchanged.
#'
#' @examples
#' # EXAMPLE 1: Allow multiple actions, but exclude an incompatible pair
#'
#' # Up to three actions may be selected per unit. Restoration and harvesting
#' # are incompatible, while threat control can accompany either one.
#'
#' base <- create_problem(
#'   pu = data.frame(id = 1:2, cost = 0),
#'   features = data.frame(id = 1L, name = "habitat"),
#'   dist_features = data.frame(pu = 1:2, feature = 1L, amount = 100)
#' ) |>
#'   add_actions(
#'     data.frame(id = c("restore", "harvest", "control", "monitor")),
#'     cost = 1
#'   ) |>
#'   add_constraint_action_cardinality(3, "max")
#'
#' exclusive <- add_constraint_action_excludes(
#'   base,
#'   actions = c("restore", "harvest"),
#'   name = "incompatible_uses"
#' )
#'
#' # EXAMPLE 2: Restrict the rule to selected planning units
#'
#' # In unit 1, choosing any one of restoration, harvesting, or control
#' # precludes the other two. The same rule is not imposed in unit 2.
#'
#' local <- add_constraint_action_excludes(
#'   base,
#'   actions = c("restore", "harvest", "control"),
#'   pu = 1L,
#'   name = "local_exclusion"
#' )
#'
#' # Inspect the stored relation, not a selected management plan.
#' local$data$constraints$action_relations[, c("type", "name")]
#'
#' @seealso [add_constraint_action_requires()], [add_constraint_action_together()],
#'   [add_constraint_action_cardinality()]
#' @export
add_constraint_action_excludes <- function(x, actions, pu = NULL, name = NULL) {
  if (missing(actions)) stop("`actions` must be provided.", call. = FALSE)
  .pa_add_action_relation(x, "excludes", actions, pu = pu, name = name)
}

#' Select actions together within each planning unit
#'
#' @description
#' Link a group of actions so that, in each specified planning unit, either
#' all are selected or none are selected.
#'
#' @details
#' \strong{How the relation works}
#'
#' Suppose restoration and threat control must be implemented as one package.
#' This relation requires both actions whenever either is selected. It does
#' **not** require either action to be selected in the first place.
#'
#' The binary decisions satisfy \eqn{x_{ia} = x_{ib}} for all members of the
#' group. Unlike [add_constraint_action_requires()], dependency is
#' bidirectional. Unlike [add_constraint_action_excludes()], simultaneous
#' selection is permitted and, when the group is used, required.
#'
#' Cardinality must allow all members to be selected. Registering a set with
#' [add_action_sets()] specifies a possible combination for joint effects;
#' it does not itself impose the together relation.
#'
#' @inheritParams add_constraint_action_requires
#' @param actions At least two action IDs or existing classification labels
#'   that must be selected together or omitted together in each scoped unit.
#' @inheritSection add_constraint_action_requires Scope and feasibility
#' @inheritSection add_constraint_action_requires Repeated calls
#' @return A new `Problem` with the relation appended. The input problem is
#'   unchanged.
#'
#' @examples
#' # EXAMPLE 1: Require restoration and control to occur together
#'
#' # In planning unit 1, restoration and control must be selected together
#' # or both omitted. Monitoring remains independently selectable.
#' # Allow two simultaneous actions in unit 1; elsewhere the default
#' # maximum of one action still applies.
#'
#' base <- create_problem(
#'   pu = data.frame(id = 1:2, cost = 0),
#'   features = data.frame(id = 1L, name = "habitat"),
#'   dist_features = data.frame(pu = 1:2, feature = 1L, amount = 100)
#' ) |>
#'   add_actions(
#'     data.frame(id = c("restore", "control", "monitor")), cost = 1
#'   ) |>
#'   add_constraint_action_cardinality(2, "max", pu = 1L)
#'
#' together <- add_constraint_action_together(
#'   base,
#'   actions = c("restore", "control"),
#'   pu = 1L,
#'   name = "restoration_package"
#' )
#'
#' # Inspect the registered requirement; no solver has been run.
#' together$data$constraints$action_relations[, c("type", "name")]
#'
#' # EXAMPLE 2: Extend the package to three actions
#'
#' # All three must be selected or omitted as a group. The cardinality
#' # upper bound must now allow three actions in the scoped unit.
#'
#' extended <- create_problem(
#'   pu = data.frame(id = 1L, cost = 0),
#'   features = data.frame(id = 1L, name = "habitat"),
#'   dist_features = data.frame(pu = 1L, feature = 1L, amount = 100)
#' ) |>
#'   add_actions(
#'     data.frame(id = c("restore", "control", "monitor")), cost = 1
#'   ) |>
#'   add_constraint_action_cardinality(3, "max") |>
#'   add_constraint_action_together(c("restore", "control", "monitor"))
#'
#' @seealso [add_constraint_action_requires()], [add_constraint_action_excludes()],
#'   [add_constraint_action_cardinality()], [add_action_sets()]
#' @export
add_constraint_action_together <- function(x, actions, pu = NULL, name = NULL) {
  if (missing(actions)) stop("`actions` must be provided.", call. = FALSE)
  .pa_add_action_relation(x, "together", actions, pu = pu, name = name)
}

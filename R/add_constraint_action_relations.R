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
  registry <- vector("list", nrow(specs))
  for (k in seq_len(nrow(specs))) {
    rows <- list()
    for (id in specs$pu[[k]]) {
      pairs <- da[da$pu == id, , drop = FALSE]
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
#' Require companion actions whenever a triggering action is selected in the
#' same planning unit. `sense = "all"` requires every companion;
#' `sense = "any"` requires at least one.
#'
#' @details
#' For each unit and each triggering action \eqn{a}, `sense = "all"` adds
#' \eqn{x_{i,a} \le x_{i,b}} for every required action \eqn{b}. `sense = "any"`
#' adds \eqn{x_{i,a} \le \sum_b x_{i,b}}. Every action in `actions` is an
#' independent trigger; selecting all of them is not a prerequisite. Triggering
#' and required groups must be disjoint. With one required action, all and any
#' have identical meaning and are stored canonically as all.
#'
#' @section Scope and feasibility:
#' Relations are applied separately within every unit in `pu`. `NULL` resolves
#' to all currently registered units. Relations do not force any action to be
#' selected and do not change the registered feasible pairs or the implicit
#' one-action maximum.
#' Use [add_constraint_action_cardinality()] to permit simultaneous actions.
#' An action that has no feasible pair, is locked out, or is removed because its
#' cost is non-finite is treated as zero. A missing required action can therefore
#' prohibit its trigger; a missing together member prohibits the other members.
#' Cycles and combinations of valid relations can make the model infeasible;
#' the solver determines joint feasibility, including conflicts with locks,
#' budgets, and cardinality. No cross-unit dependency or temporal order is implied.
#' Registered joint effects support concurrent economic and ecological
#' workflows. Benefit maximizes signed joint change; loss minimizes final
#' deterioration within each unit and feature. Ecological targets count the
#' reference once per selected unit within their action scope.
#'
#' @section Repeated calls:
#' Distinct relations accumulate in `x$data$constraints$action_relations` and
#' apply simultaneously. Duplicate combinations of type, action groups, sense,
#' and PU scope raise an error, regardless of the name. Names must be unique
#' across requires, excludes, and together relations. Ordering and repeated IDs
#' in input vectors do not change identity. Names label constraints independently
#' of objective aliases. To change a relation, rebuild from the preceding problem.
#'
#' @param x A `Problem` with registered actions.
#' @param actions Non-empty vector of triggering action IDs or legacy
#'   `actions$action_set` classification labels. For excludes/together, this is
#'   the group of mutually exclusive or jointly selected actions and must resolve
#'   to at least two distinct actions. Display names and IDs registered with
#'   [add_action_sets()] are not accepted; supply their individual members.
#' @param requires Non-empty vector of required action IDs or legacy
#'   classification labels, disjoint from `actions`.
#' @param sense `"all"` (default) or `"any"` required companions.
#' @param pu Optional vector of external planning-unit IDs. `NULL` applies
#'   the relation to all currently registered units.
#' @param name Optional non-empty, unique constraint label. A name is generated
#'   if omitted.
#'
#' @return A new `Problem` with the relation appended and compiled caches
#'   invalidated. The input problem is preserved.
#'
#' @examples
#' base <- create_problem(
#'   pu = data.frame(id = c(10L, 20L), cost = 0),
#'   features = data.frame(id = 1L),
#'   dist_features = data.frame(pu = c(10L, 20L), feature = 1L, amount = 100)
#' ) |>
#'   add_actions(data.frame(id = c("restore", "control", "fence", "monitor")), cost = 1) |>
#'   add_constraint_action_cardinality(3, "max")
#'
#' # Restoration requires threat control in unit 10.
#' required <- base |>
#'   add_constraint_action_requires("restore", "control", pu = 10L)
#'
#' # In unit 20, either control or fencing is sufficient.
#' required <- required |>
#'   add_constraint_action_requires(
#'     "restore", c("control", "fence"), sense = "any", pu = 20L
#'   )
#' required$data$constraints$action_relations
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
#' Allow at most one selected action from the specified group in each unit.
#' All actions in the group may remain unselected.
#'
#' @details
#' For each scoped unit, the relation is \eqn{\sum_{a \in A} x_{i,a} \le 1}.
#' For three or more actions this excludes every pair, not just selection of the
#' complete group. Actions outside the group are unrestricted by this relation.
#'
#' @inheritParams add_constraint_action_requires
#' @inheritSection add_constraint_action_requires Scope and feasibility
#' @inheritSection add_constraint_action_requires Repeated calls
#' @return A new `Problem` with the relation appended and compiled caches
#'   invalidated. The input problem is preserved.
#' @examples
#' base <- create_problem(
#'   pu = data.frame(id = 1:2, cost = 0),
#'   features = data.frame(id = 1L),
#'   dist_features = data.frame(pu = 1:2, feature = 1L, amount = 100)
#' ) |>
#'   add_actions(data.frame(id = c("restore", "harvest", "control")), cost = 1) |>
#'   add_constraint_action_cardinality(2, "max")
#'
#' exclusive <- base |>
#'   add_constraint_action_excludes(c("restore", "harvest"), name = "incompatible_uses")
#' exclusive$data$constraints$action_relations
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
#' Require all actions in a group to be selected together or all to remain
#' unselected in each scoped unit.
#'
#' @details
#' The relation equates the binary action decisions \eqn{x_{i,a} = x_{i,b}} for
#' every pair of group members. This expresses both directions of dependency;
#' it does not require implementation of the group. Registering an action set
#' alone does not add this relation. Cardinality must permit the full group if
#' it is to be selected.
#'
#' @inheritParams add_constraint_action_requires
#' @inheritSection add_constraint_action_requires Scope and feasibility
#' @inheritSection add_constraint_action_requires Repeated calls
#' @return A new `Problem` with the relation appended and compiled caches
#'   invalidated. The input problem is preserved.
#' @examples
#' base <- create_problem(
#'   pu = data.frame(id = 1:2, cost = 0),
#'   features = data.frame(id = 1L),
#'   dist_features = data.frame(pu = 1:2, feature = 1L, amount = 100)
#' ) |>
#'   add_actions(data.frame(id = c("restore", "control", "monitor")), cost = 1) |>
#'   add_constraint_action_cardinality(2, "max")
#'
#' joint <- base |>
#'   add_constraint_action_together(c("restore", "control"), pu = 1L)
#' joint$data$constraints$action_relations
#' @seealso [add_constraint_action_requires()], [add_constraint_action_excludes()],
#'   [add_action_sets()]
#' @export
add_constraint_action_together <- function(x, actions, pu = NULL, name = NULL) {
  if (missing(actions)) stop("`actions` must be provided.", call. = FALSE)
  .pa_add_action_relation(x, "together", actions, pu = pu, name = name)
}

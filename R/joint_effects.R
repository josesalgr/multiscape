#' @include internal.R
NULL

.pa_member_key <- function(members) {
  members <- sort(as.character(members), method = "radix")
  paste(nchar(members, type = "bytes"), members, sep = ":", collapse = "|")
}

# Expand sets only in a temporary input catalogue. These are never decisions.
.pa_joint_effects_input <- function(x, effects, modern) {
  sets <- x$data$action_sets
  if (is.null(sets) || !nrow(sets)) return(NULL)
  sets <- .pa_validate_action_sets(sets, x$data$actions)
  supplied <- if (is.data.frame(effects)) {
    as.character(effects[[if ("action" %in% names(effects)) "action" else "id"]])
  } else if (is.list(effects)) names(effects) else character()
  used <- intersect(unique(supplied), unique(sets$set))
  if (!length(used)) return(NULL)
  if (!modern) stop("Joint effects require the modern effect/outcome/relative_change or raster interface; legacy filtering is not supported for sets.", call. = FALSE)
  original <- list(actions = x$data$actions, dist_actions = x$data$dist_actions,
                   input = if (is.data.frame(effects)) effects else NULL)
  available <- .pa_cardinality_available_pairs(original$dist_actions)
  extra <- list()
  for (s in used) {
    members <- sets$action[sets$set == s]
    ids <- x$data$pu$id[vapply(x$data$pu$id, function(id) {
      all(members %in% available$action[available$pu == id])
    }, logical(1))]
    if (is.data.frame(effects) && "pu" %in% names(effects)) {
      requested <- effects$pu[as.character(effects[[if ("action" %in% names(effects)) "action" else "id"]]) == s]
      if (anyNA(requested) || any(!requested %in% ids)) {
        stop("Joint effect '", s, "' requires all members to have available pairs in every supplied PU.", call. = FALSE)
      }
    }
    row <- original$actions[1L, , drop = FALSE]
    row$id <- s
    row$internal_id <- nrow(x$data$actions) + 1L
    if ("name" %in% names(row)) row$name <- s
    x$data$actions <- rbind(x$data$actions, row)
    if (length(ids)) {
      pairs <- original$dist_actions[rep(1L, length(ids)), , drop = FALSE]
      pairs$pu <- ids
      pairs$action <- s
      pairs$cost <- 0
      pairs$status <- 0L
      pairs$internal_pu <- x$data$pu$internal_id[match(ids, x$data$pu$id)]
      pairs$internal_action <- row$internal_id
      extra[[s]] <- pairs
    }
  }
  x$data$dist_actions <- do.call(dplyr::bind_rows, c(list(original$dist_actions), unname(extra)))
  list(problem = x, original = original, sets = sets)
}

.pa_finish_joint_effects <- function(x, context) {
  supplied <- x$data$dist_effects
  sets <- context$sets
  x$data$actions <- context$original$actions
  x$data$dist_actions <- context$original$dist_actions
  joint <- supplied$action %in% sets$set
  supplied$kind <- ifelse(joint, "set", "action")
  supplied$members <- lapply(supplied$action, function(id) {
    if (id %in% sets$set) sort(sets$action[sets$set == id], method = "radix") else id
  })
  supplied$internal_action[joint] <- NA_integer_
  terms <- supplied[, c("pu", "action", "feature", "internal_pu", "internal_feature", "kind", "members", "effect"), drop = FALSE]
  terms$total_effect <- terms$effect
  terms$member_key <- vapply(terms$members, .pa_member_key, character(1))
  if (anyDuplicated(terms[, c("pu", "feature", "member_key")])) {
    stop("Duplicated joint-effect membership scope: different set identifiers specify the same combination for a PU and feature.", call. = FALSE)
  }
  sizes <- lengths(terms$members)
  terms <- terms[order(terms$pu, terms$feature, sizes, terms$member_key), , drop = FALSE]
  groups <- split(seq_len(nrow(terms)), paste(terms$pu, terms$feature, sep = ":"))
  for (rows in groups) {
    for (k in seq_along(rows)) {
      j <- rows[k]
      earlier <- rows[seq_len(k - 1L)]
      contained <- vapply(earlier, function(t) {
        length(terms$members[[t]]) < length(terms$members[[j]]) &&
          all(terms$members[[t]] %in% terms$members[[j]])
      }, logical(1))
      terms$effect[j] <- terms$total_effect[j] - sum(terms$effect[earlier[contained]])
    }
  }
  if (any(!is.finite(terms$effect))) stop("Joint-effect corrections overflowed; use a consistent numerical scale.", call. = FALSE)
  rownames(terms) <- NULL
  x$data$effects_original <- supplied
  x$data$effects_input <- context$original$input
  x$data$joint_effects <- supplied[joint, , drop = FALSE]
  x$data$effect_terms <- terms
  x$data$dist_effects <- supplied[!joint, setdiff(names(supplied), c("kind", "members")), drop = FALSE]
  x$data$effects_meta$joint_effects <- TRUE
  x$data$effects_meta$missing_interactions <- "zero"
  x$data$effects_meta$missing_individual_effects <- "zero"
  x$data$effects_meta$decomposition <- "subset corrections of supplied total signed effects"
  x
}

.pa_has_joint_effects <- function(x) isTRUE(x$data$effects_meta$joint_effects)

.pa_uses_aggregate_effects <- function(x) {
  if (.pa_has_joint_effects(x)) return(TRUE)
  de <- x$data$dist_effects_model %||% x$data$dist_effects
  if (!is.data.frame(de) || !nrow(de)) return(FALSE)
  upper <- .pa_action_cardinality_upper_bounds(x)
  any(upper[as.character(de$pu)] > 1L)
}

.pa_prepare_joint_effects_model <- function(x) {
  if (!.pa_uses_aggregate_effects(x)) return(x)
  terms <- x$data$effect_terms
  if (!.pa_has_joint_effects(x)) {
    de <- x$data$dist_effects_model
    terms <- de[, c("pu", "action", "feature", "internal_pu", "internal_feature", "effect"), drop = FALSE]
    terms$kind <- "action"
    terms$members <- lapply(as.character(terms$action), identity)
    terms$member_key <- vapply(terms$members, .pa_member_key, character(1))
  }
  if (!is.data.frame(terms) || !all(c("pu", "feature", "members", "effect", "kind", "member_key") %in% names(terms)) ||
      !is.list(terms$members) || anyNA(terms$effect) || any(!is.finite(terms$effect))) {
    stop("Stored joint-effect terms are malformed.", call. = FALSE)
  }
  if (.pa_has_joint_effects(x)) .pa_validate_action_sets(x$data$action_sets, x$data$actions)
  da <- x$data$dist_actions_model
  for (k in seq_len(nrow(terms))) {
    m <- terms$members[[k]]
    if (!length(m) || anyNA(m) || anyDuplicated(m) || any(!m %in% x$data$actions$id) ||
        !terms$pu[k] %in% x$data$pu$id || !terms$feature[k] %in% x$data$features$id ||
        !identical(terms$member_key[k], .pa_member_key(m))) {
      stop("Stored joint-effect terms contain invalid members, PU, or feature identifiers.", call. = FALSE)
    }
  }
  upper <- .pa_action_cardinality_upper_bounds(x)
  usable <- vapply(seq_len(nrow(terms)), function(k) {
    m <- terms$members[[k]]
    id <- terms$pu[k]
    if (!all(m %in% da$action[da$pu == id]) || length(m) > upper[as.character(id)]) return(FALSE)
    specs <- x$data$constraints$action_cardinality
    if (!is.null(specs)) for (j in seq_len(nrow(specs))) {
      if (id %in% specs$pu[[j]] && specs$sense[j] %in% c("max", "equal")) {
        counted <- if (is.null(specs$actions[[j]])) length(m) else sum(m %in% specs$actions[[j]])
        if (counted > specs$count[j]) return(FALSE)
      }
    }
    rel <- x$data$constraints$action_relations
    if (!is.null(rel)) for (j in seq_len(nrow(rel))) {
      if (rel$type[j] == "excludes" && id %in% rel$pu[[j]] && sum(m %in% rel$actions[[j]]) > 1L) return(FALSE)
    }
    TRUE
  }, logical(1))
  # Retain zero input rows for provenance; never allocate auxiliaries for them.
  x$data$effect_terms_model <- terms[usable & terms$effect != 0, , drop = FALSE]
  x
}

.pa_build_joint_effects <- function(x) {
  if (!.pa_uses_aggregate_effects(x)) return(x)
  terms <- x$data$effect_terms_model
  x <- .pa_refresh_model_snapshot(x)
  da <- x$data$dist_actions_model
  terms$column0 <- integer(nrow(terms))
  individual <- terms$kind == "action"
  for (k in which(individual)) {
    row <- which(da$pu == terms$pu[k] & da$action == terms$members[[k]])
    terms$column0[k] <- x$data$model_list$x_offset + da$internal_row[row] - 1L
  }
  joint <- terms[!individual, , drop = FALSE]
  keys <- paste(joint$pu, joint$member_key, sep = ":")
  first <- !duplicated(keys)
  groups <- joint[first, c("pu", "action", "members", "member_key"), drop = FALSE]
  columns <- lapply(seq_len(nrow(groups)), function(k) {
    rows <- match(groups$members[[k]], da$action[da$pu == groups$pu[k]])
    pairs <- da[da$pu == groups$pu[k], , drop = FALSE]
    as.integer(x$data$model_list$x_offset + pairs$internal_row[rows] - 1L)
  })
  activation <- rcpp_add_joint_effect_variables(x$data$model_ptr, columns)
  groups$column0 <- as.integer(activation$columns0)
  terms$column0[!individual] <- groups$column0[match(keys, paste(groups$pu, groups$member_key, sep = ":"))]
  x$data$effect_terms_model <- terms
  x$data$joint_variables_model <- groups
  x$data$model_registry$vars$joint_effects <- activation
  x <- .pa_refresh_model_snapshot(x)
  # All inferred action outcomes must remain physically non-negative.
  scopes <- split(seq_len(nrow(terms)), paste(terms$pu, terms$feature, sep = ":"))
  nonnegative <- list()
  for (rows in scopes) {
    df <- x$data$dist_features
    ref <- sum(df$amount[df$pu == terms$pu[rows[1]] & df$feature == terms$feature[rows[1]]])
    if (any(terms$effect[rows] < 0)) {
      nonnegative[[length(nonnegative) + 1L]] <- rcpp_add_linear_constraint(
        x$data$model_ptr, as.integer(terms$column0[rows]), as.numeric(terms$effect[rows]),
        ">=", ref * -1, name = paste0("joint_outcome_", terms$pu[rows[1]], "_", terms$feature[rows[1]]),
        block_name = "joint_outcomes")
    }
  }
  x$data$model_registry$cons$joint_outcomes <- nonnegative
  x
}

.pa_joint_objective_terms <- function(x, column = "effect", actions = NULL, features = NULL) {
  terms <- x$data$effect_terms_model
  if (!is.null(actions)) {
    ids <- as.character(actions)
    # Existing benefit/loss definitions store internal indices, also serialized
    # as strings by MO IR. Otherwise use the normal external-ID resolver.
    index <- suppressWarnings(as.integer(ids))
    if (length(index) && all(!is.na(index) & index %in% x$data$actions$internal_id)) {
      ids <- as.character(x$data$actions$id[match(index, x$data$actions$internal_id)])
    } else ids <- as.character(.pa_resolve_action_subset(x, ids)$id)
    terms <- terms[vapply(terms$members, function(m) all(m %in% ids), logical(1)), , drop = FALSE]
  }
  if (!is.null(features)) {
    ids <- suppressWarnings(as.integer(features))
    if (!all(!is.na(ids) & ids %in% x$data$features$internal_id)) {
      ids <- x$data$features$internal_id[match(as.character(features), x$data$features$name)]
    }
    if (anyNA(ids)) stop("Unknown feature subset in joint objective.", call. = FALSE)
    terms <- terms[terms$internal_feature %in% ids, , drop = FALSE]
  }
  if (!column %in% c("effect", "benefit", "loss")) {
    stop("Aggregate objectives support signed effect or final loss coefficients.", call. = FALSE)
  }
  terms
}

.pa_joint_objective_vector <- function(x, column = "effect", actions = NULL, features = NULL) {
  terms <- .pa_joint_objective_terms(x, column, actions, features)
  n <- length(rcpp_optimization_problem_as_list(x$data$model_ptr)$obj)
  vector <- numeric(n)
  if (column == "loss") {
    for (rows in .pa_effect_scopes(terms)) {
      coefficients <- terms$effect[rows]
      if (all(coefficients >= 0)) next
      if (all(coefficients <= 0)) {
        sums <- tapply(-coefficients, terms$column0[rows], sum)
        vector[as.integer(names(sums)) + 1L] <- vector[as.integer(names(sums)) + 1L] + as.numeric(sums)
      } else {
        key <- .pa_effect_loss_key(terms, rows)
        column0 <- x$data$effect_loss_columns[[key]]
        if (is.null(column0)) stop("Missing final-loss auxiliary in the compiled model.", call. = FALSE)
        vector[column0 + 1L] <- vector[column0 + 1L] + 1
      }
    }
    return(vector)
  }
  if (nrow(terms)) {
    sums <- tapply(terms$effect, terms$column0, sum)
    vector[as.integer(names(sums)) + 1L] <- as.numeric(sums)
  }
  vector
}

.pa_effect_scopes <- function(terms) {
  split(seq_len(nrow(terms)), paste(terms$internal_pu, terms$internal_feature, sep = ":"))
}

.pa_eval_aggregate_effect_objective <- function(x, solution, type, actions = NULL, features = NULL) {
  terms <- .pa_joint_objective_terms(x, "effect", actions, features)
  da <- x$data$dist_actions_model
  columns <- x$data$model_list$x_offset + da$internal_row
  if (length(columns) && (max(columns) > length(solution) || anyNA(solution[columns]))) {
    stop("Solution does not contain valid atomic action decisions.", call. = FALSE)
  }
  da$selected <- solution[columns] > .5
  active <- vapply(seq_len(nrow(terms)), function(k) {
    all(terms$members[[k]] %in% da$action[da$pu == terms$pu[k] & da$selected])
  }, logical(1))
  changes <- vapply(.pa_effect_scopes(terms), function(rows) {
    sum(terms$effect[rows] * active[rows])
  }, numeric(1))
  if (type == "loss") sum(pmax(-changes, 0)) else sum(changes)
}

.pa_effect_loss_key <- function(terms, rows) {
  paste(terms$internal_pu[rows[1]], terms$internal_feature[rows[1]],
        paste(terms$column0[rows], format(terms$effect[rows], digits = 17, scientific = TRUE),
              sep = "=", collapse = ";"), sep = "|")
}

.pa_build_effect_losses <- function(x) {
  if (!.pa_uses_aggregate_effects(x)) return(x)
  args <- x$data$model_args
  scopes <- args$needs$effect_loss_scopes %||% list()
  if (identical(args$model_type, "minimizeLosses")) {
    scopes <- c(scopes, list(args$objective_args %||% list()))
  }
  expressions <- list()
  for (scope in scopes) {
    terms <- .pa_joint_objective_terms(x, "effect", scope$actions, scope$features)
    for (rows in .pa_effect_scopes(terms)) {
      coefs <- terms$effect[rows]
      if (!any(coefs < 0) || !any(coefs > 0)) next
      key <- .pa_effect_loss_key(terms, rows)
      expressions[[key]] <- list(columns0 = as.integer(terms$column0[rows]), coefficients = as.numeric(coefs))
    }
  }
  result <- rcpp_add_effect_loss_variables(x$data$model_ptr,
    lapply(expressions, `[[`, "columns0"), lapply(expressions, `[[`, "coefficients"))
  x$data$effect_loss_columns <- stats::setNames(as.list(as.integer(result$columns0)), names(expressions))
  x$data$model_registry$vars$effect_losses <- result
  .pa_refresh_model_snapshot(x)
}

# Targets use reference + joint change, crediting the reference only once when
# at least one action in the target scope is implemented in a planning unit.
.pa_apply_aggregate_targets <- function(x, targets) {
  da <- x$data$dist_actions_model
  df <- x$data$dist_features
  selection_columns <- list()
  applied <- list()
  for (k in seq_len(nrow(targets))) {
    target <- targets[k, , drop = FALSE]
    feature <- x$data$features$internal_id[match(target$feature, x$data$features$id)]
    if (is.na(feature)) stop("Some target features could not be mapped to internal feature ids.", call. = FALSE)
    actions <- NULL
    pairs <- da
    if (!is.na(target$actions) && nzchar(target$actions)) {
      actions <- .pa_resolve_action_subset(x, strsplit(target$actions, "\\|")[[1]])$internal_id
      pairs <- da[da$internal_action %in% actions, , drop = FALSE]
    }
    terms <- .pa_joint_objective_terms(x, "effect", actions, feature)
    columns <- as.integer(terms$column0)
    values <- as.numeric(terms$effect)
    for (pu in unique(pairs$pu)) {
      reference <- sum(df$amount[df$pu == pu & df$feature == target$feature])
      if (reference == 0) next
      rows <- pairs[pairs$pu == pu, , drop = FALSE]
      if (is.null(actions)) {
        column0 <- x$data$model_list$w_offset + rows$internal_pu[1] - 1L
      } else {
        action_columns <- as.integer(x$data$model_list$x_offset + rows$internal_row - 1L)
        if (length(action_columns) == 1L) column0 <- action_columns else {
          key <- paste(sort(action_columns), collapse = ":")
          column0 <- selection_columns[[key]]
          if (is.null(column0)) {
            result <- rcpp_add_effect_selection_variables(x$data$model_ptr, list(action_columns))
            column0 <- as.integer(result$columns0)[1]
            selection_columns[[key]] <- column0
          }
        }
      }
      columns <- c(columns, column0)
      values <- c(values, reference)
    }
    if (!length(columns) || all(values == 0)) {
      stop("Infeasible targets detected: target has no non-zero reference or effect contributions.", call. = FALSE)
    }
    applied[[k]] <- rcpp_add_linear_constraint(x$data$model_ptr, columns, values, ">=",
      as.numeric(target$target_value), name = paste0("feature_target_", k), block_name = "feature_targets")
  }
  x$data$model_registry$cons$feature_targets <- applied
  x$data$model_args$targets_applied <- TRUE
  x$data$model_args$targets_counts <- list(actions = nrow(targets))
  x
}

# Feature summaries for joint models are evaluated once per PU/feature.
.pa_joint_selected_features <- function(x, da_out, actions = NULL) {
  df <- x$data$dist_features
  in_scope <- if (is.null(actions)) rep(TRUE, nrow(da_out)) else da_out$internal_action %in% actions
  active <- unique(da_out$pu[da_out$selected > 0.5 & in_scope])
  terms <- .pa_joint_objective_terms(x, "effect", actions)
  scopes <- unique(rbind(df[, c("pu", "feature")], terms[, c("pu", "feature")]))
  scopes$internal_feature <- x$data$features$internal_id[match(scopes$feature, x$data$features$id)]
  scopes$selected_net <- vapply(seq_len(nrow(scopes)), function(k) {
    id <- scopes$pu[k]
    selected <- da_out$action[da_out$pu == id & da_out$selected > 0.5]
    rows <- which(terms$pu == id & terms$feature == scopes$feature[k])
    sum(terms$effect[rows][vapply(terms$members[rows], function(m) all(m %in% selected), logical(1))])
  }, numeric(1))
  scopes$selected_baseline <- vapply(seq_len(nrow(scopes)), function(k) {
    if (!scopes$pu[k] %in% active) return(0)
    sum(df$amount[df$pu == scopes$pu[k] & df$feature == scopes$feature[k]])
  }, numeric(1))
  scopes$selected_amount_after <- scopes$selected_baseline + scopes$selected_net
  scopes$selected_benefit <- pmax(scopes$selected_net, 0)
  scopes$selected_loss <- pmax(-scopes$selected_net, 0)
  scopes
}

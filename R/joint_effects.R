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

.pa_prepare_joint_effects_model <- function(x) {
  if (!.pa_has_joint_effects(x)) return(x)
  terms <- x$data$effect_terms
  if (!is.data.frame(terms) || !all(c("pu", "feature", "members", "effect", "kind", "member_key") %in% names(terms)) ||
      !is.list(terms$members) || anyNA(terms$effect) || any(!is.finite(terms$effect))) {
    stop("Stored joint-effect terms are malformed.", call. = FALSE)
  }
  .pa_validate_action_sets(x$data$action_sets, x$data$actions)
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
  if (is.data.frame(x$data$targets) && nrow(x$data$targets) &&
      any(upper[as.character(terms$pu)] > 1L)) {
    stop("Concurrent joint-effect targets require final feature aggregation (point 5); per-action amount_after would repeat the reference.", call. = FALSE)
  }
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
  if (!.pa_has_joint_effects(x)) return(x)
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
    stop("Joint objectives currently support effect, benefit, or loss coefficients; amount_after requires the feature-aggregation stage.", call. = FALSE)
  }
  if ((column == "benefit" && any(terms$effect < 0)) ||
      (column == "loss" && any(terms$effect > 0))) {
    stop("Mixed signed joint effects require final feature aggregation before benefit/loss optimization (point 5). Use a cost/profit objective in this stage.", call. = FALSE)
  }
  if (column == "loss") terms$effect <- -terms$effect
  terms
}

.pa_joint_objective_vector <- function(x, column = "effect", actions = NULL, features = NULL) {
  terms <- .pa_joint_objective_terms(x, column, actions, features)
  n <- length(rcpp_optimization_problem_as_list(x$data$model_ptr)$obj)
  vector <- numeric(n)
  if (nrow(terms)) {
    sums <- tapply(terms$effect, terms$column0, sum)
    vector[as.integer(names(sums)) + 1L] <- as.numeric(sums)
  }
  vector
}

# Feature summaries for joint models are evaluated once per PU/feature.
.pa_joint_selected_features <- function(x, da_out) {
  df <- x$data$dist_features
  active <- unique(da_out$pu[da_out$selected > 0.5])
  terms <- x$data$effect_terms_model
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

#' @include internal.R
#'
#' @title Add action effects to a planning problem
#' @description
#' Describe how feasible actions change feature amounts relative to a
#' user-defined reference scenario.
#'
#' @details
#' Effects can be defined only once per problem. A second call, including through
#' \code{add_benefits()} or \code{add_losses()}, raises an error. Supply the
#' complete effects table in one call. To compare effect scenarios, build
#' separate problems from the object before effects were added.
#'
#' The feature distribution supplied to \code{create_problem()} defines the
#' reference amounts. The reference can describe current conditions, a future
#' without intervention, or existing management. Action outcomes and references
#' must share units and, for future scenarios, the same time horizon.
#'
#' \strong{Tabular inputs}
#'
#' Supply a table with \code{action}, \code{feature}, optional \code{pu}, and
#' exactly one of these numeric columns:
#' \itemize{
#'   \item \code{effect}: signed absolute change relative to the reference.
#'   \item \code{outcome}: feature amount under the action.
#'   \item \code{relative_change}: proportional change; 0.25 means +25 percent,
#'   zero means no change, and -0.25 means a 25 percent decrease.
#' }
#' If \code{pu} is omitted, each action/feature specification is expanded over
#' feasible planning-unit/action pairs. Actions must be defined first using
#' \code{add_actions()}; locked-out pairs are excluded. Features may be supplied
#' as numeric identifiers or names. Duplicate keys and ambiguous columns are
#' rejected. Values must be numeric, finite, and non-missing. Computed outcomes
#' must be non-negative. Missing reference amounts are zero, so relative change
#' cannot create an amount from a zero reference; use \code{effect} or
#' \code{outcome} in that case.
#'
#' \strong{Canonical representation}
#'
#' For reference amount \eqn{r_{if}} and action outcome \eqn{q_{iaf}}, the signed
#' effect is \eqn{e_{iaf} = q_{iaf} - r_{if}}. Relative-change inputs \eqn{c_{iaf}}
#' are converted using \eqn{e_{iaf} = r_{if} c_{iaf}}. The stored table exposes
#' \code{reference_amount}, \code{action_outcome}, and \code{effect}. It also
#' retains \code{amount_after} as an alias of \code{action_outcome}, plus
#' \eqn{\mathrm{benefit} = \max(e, 0)} and \eqn{\mathrm{loss} = \max(-e, 0)}.
#' These components cannot both be positive for a single triple.
#' A positive effect denotes an increase, not necessarily an improvement:
#' whether increasing a feature is desirable depends on the objective.
#' Zero effects are retained and have an outcome equal to the reference amount.
#'
#' \strong{Joint effects of action sets}
#'
#' In the modern table or raster interface, \code{action} can also identify a
#' set registered with \code{add_action_sets()}. Supply the total outcome or
#' total change of that combination, not an interaction coefficient. Individual
#' and joint effects belong in the same single call. Set members must share an
#' available PU; a global row expands only over such units. Explicit joint rows
#' with unavailable members raise an error. Legacy component filtering is not
#' supported for joint effects.
#'
#' The original canonical totals are preserved in \code{effects_original} and
#' \code{joint_effects}; original table input is preserved in \code{effects_input}.
#' \code{dist_effects} continues to contain individual actions only. The separate
#' \code{effect_terms} table stores signed corrections: for set S, subtract all
#' supplied proper-subset corrections from its supplied total change.
#' Unspecified individual effects and interactions are explicitly assumed zero,
#' recorded in \code{effects_meta}. This is a modelling assumption, not evidence
#' that unobserved interactions are absent.
#'
#' Compilation adds an exact AND auxiliary only for a feasible PU/set with a
#' non-zero correction. It is continuous on `0 <= y <= 1`, determined by the binary
#' members, shared across features, and activated independently of coefficient
#' sign or optimization method. Cardinality still determines allowed action
#' counts; registration and effects do not force joint selection. Inferred
#' negative feature outcomes are excluded from the feasible set.
#'
#' Benefit objectives maximize total signed change, including negative effects
#' and interaction corrections. Loss objectives minimize the negative part of
#' the final joint change per PU/feature, rather than treating a negative
#' correction as a loss by itself. Concurrent individual effects are additive
#' when no interaction is supplied. Targets use the joint outcome and count the
#' reference once per unit in their action scope. Solution summaries report
#' signed net change and its final positive/negative parts separately.
#'
#' \strong{Raster inputs}
#'
#' Supply a named list of \code{terra::SpatRaster} objects, one per action.
#' Names must match action identifiers. Each raster must have one layer per
#' feature, in the order of the problem's feature catalogue; layer names do not
#' reorder features. The problem must contain planning-unit geometry or a
#' planning-unit raster. Rasters are aligned to the planning-unit raster when
#' needed. Use \code{raster_type = "effect"} for signed changes or
#' \code{raster_type = "outcome"} for feature amounts under the action.
#' \code{raster_aggregation} specifies \code{"sum"} or \code{"mean"} within
#' each planning unit. Aggregated values must be comparable with the reference:
#' do not compare a mean outcome with a reference total. Relative-change rasters
#' are not accepted directly; prepare a tabular relative-change specification
#' or a raster of effects/outcomes first.
#'
#' \strong{Compatibility with earlier versions}
#'
#' Explicit legacy arguments \code{effect_type}, \code{effect_aggregation}, and
#' \code{component}, and historical \code{delta}, \code{after},
#' \code{multiplier}, \code{benefit}, and \code{loss} inputs remain supported
#' with their existing behavior. They emit a \pkg{lifecycle} deprecation warning
#' announcing removal in a future release. Positional legacy arguments keep
#' their original order. New table inputs need no interpretation argument.
#'
#' @param x A \code{Problem} object created by \code{\link{create_problem}}
#'   with feasible actions defined by \code{\link{add_actions}}.
#' @param effects A table with \code{action}, \code{feature}, optional
#'   \code{pu}, and exactly one of \code{effect}, \code{outcome}, or
#'   \code{relative_change}; a named list of action rasters; or \code{NULL}
#'   to store an empty effects table. Historical input formats remain supported.
#' @param effect_type Deprecated interpretation argument: \code{"delta"}
#'   for changes or \code{"after"} for action amounts. With historical
#'   multipliers, delta means reference times multiplier; after means an outcome
#'   equal to reference times multiplier. Omit for new table inputs.
#' @param effect_aggregation Deprecated raster aggregation argument; use
#'   \code{raster_aggregation}.
#' @param component Deprecated filtering argument: \code{"any"} retains all
#'   rows, \code{"benefit"} retains positive changes, and \code{"loss"}
#'   retains negative changes. New calls retain all components.
#' @param raster_aggregation Raster aggregation within planning units:
#'   \code{"sum"} (default) or \code{"mean"}.
#' @param raster_type Raster interpretation: \code{"effect"} (default) or
#'   \code{"outcome"}. Explicitly supply this or \code{raster_aggregation}
#'   to select the new raster interface.
#' @return An updated \code{Problem} containing \code{dist_effects} and
#'   \code{effects_meta}. Existing model coefficients remain available.
#'
#' @examples
#' p <- create_problem(
#'   pu = data.frame(id = 1, cost = 1),
#'   features = data.frame(id = 1, name = "habitat"),
#'   dist_features = data.frame(pu = 1, feature = 1, amount = 100)
#' ) |>
#'   add_actions(actions = data.frame(id = "restore"))
#'
#' # Equivalent ways to specify an increase from 100 to 150.
#' p_effect <- add_effects(p, data.frame(
#'   pu = 1, action = "restore", feature = "habitat", effect = 50
#' ))
#' p_outcome <- add_effects(p, data.frame(
#'   pu = 1, action = "restore", feature = "habitat", outcome = 150
#' ))
#' p_relative <- add_effects(p, data.frame(
#'   action = "restore", feature = "habitat", relative_change = 0.50
#' ))
#' p_effect$data$dist_effects[, c("reference_amount", "effect", "action_outcome")]
#'
#' # Joint totals in one call: 30 + 20 + interaction 20 = total 70.
#' joint_base <- create_problem(
#'   data.frame(id = 10L, cost = 0), data.frame(id = 1L, name = "habitat"),
#'   data.frame(pu = 10L, feature = 1L, amount = 100)
#' ) |>
#'   add_actions(data.frame(id = c("restore", "control")), cost = 1) |>
#'   add_action_sets(list(restore_control = c("restore", "control"))) |>
#'   add_constraint_action_cardinality(2, "max")
#' joint <- joint_base |>
#'   add_effects(data.frame(
#'     action = c("restore", "control", "restore_control"),
#'     feature = "habitat", effect = c(30, 20, 70)
#'   ))
#' joint$data$effect_terms[, c("action", "total_effect", "effect")]
#'
#' # Raster example: one polygon contains two cells with reference amounts 40, 60.
#' r <- terra::rast(nrows = 1, ncols = 2, xmin = 0, xmax = 2,
#'                  ymin = 0, ymax = 1, crs = "EPSG:3857")
#' terra::values(r) <- c(40, 60)
#' names(r) <- "habitat"
#' polygon <- sf::st_polygon(list(matrix(
#'   c(0, 0, 2, 0, 2, 1, 0, 1, 0, 0), ncol = 2, byrow = TRUE
#' )))
#' pu <- sf::st_sf(id = 1L, cost = 1,
#'                 geometry = sf::st_sfc(polygon, crs = 3857))
#' p_spatial <- create_problem(pu = pu, features = r, cost = "cost") |>
#'   add_actions(actions = data.frame(id = "restore"))
#' terra::values(r) <- c(20, 30)
#' p_raster <- add_effects(p_spatial, list(restore = r),
#'                        raster_type = "effect", raster_aggregation = "sum")
#' terra::values(r) <- c(60, 90)
#' p_raster_outcome <- add_effects(p_spatial, list(restore = r),
#'                                raster_type = "outcome", raster_aggregation = "sum")
#' p_raster$data$dist_effects[, c("reference_amount", "effect", "action_outcome")]
#'
#' @seealso \code{\link{add_actions}}, \code{\link{add_benefits}},
#'   \code{\link{add_losses}}
#' @export
add_effects <- function(
    x,
    effects = NULL,
    effect_type = c("delta", "after"),
    effect_aggregation = c("sum", "mean"),
    component = c("any", "benefit", "loss"),
    raster_aggregation = c("sum", "mean"),
    raster_type = c("effect", "outcome")
) {
  assertthat::assert_that(!is.null(x), msg = "x is NULL")
  .pa_assert_unconfigured(x, c("dist_effects", "dist_benefit", "dist_loss"),
                         "Effects", "add_effects() (including add_benefits()/add_losses())")
  legacy_type <- !missing(effect_type)
  legacy_aggregation <- !missing(effect_aggregation)
  legacy_component <- !missing(component)
  legacy_raster <- is.list(effects) && !is.data.frame(effects) &&
    !is.null(effects) && missing(raster_type) && missing(raster_aggregation)
  if (legacy_aggregation && !missing(raster_aggregation)) {
    stop("Supply only one of raster_aggregation and effect_aggregation.", call. = FALSE)
  }
  if (legacy_type && !missing(raster_type)) {
    stop("Supply only one of raster_type and effect_type.", call. = FALSE)
  }
  input_columns <- if (is.data.frame(effects)) names(effects) else character()
  semantic_columns <- intersect(c("effect", "outcome", "relative_change"), input_columns)
  legacy_columns <- intersect(c("delta", "after", "multiplier", "benefit", "loss"), input_columns)
  if (length(semantic_columns) > 1L ||
      (any(c("outcome", "relative_change") %in% semantic_columns) && length(legacy_columns) > 0L)) {
    stop("Ambiguous effect specification: supply exactly one of effect, outcome, or relative_change; do not mix new and legacy columns.", call. = FALSE)
  }
  if (any(c("outcome", "relative_change") %in% semantic_columns) && legacy_type) {
    stop("outcome and relative_change define their own interpretation; omit effect_type.", call. = FALSE)
  }
  if (legacy_type || legacy_aggregation || legacy_component || legacy_raster || length(legacy_columns) > 0L) {
    caller <- sys.function(sys.parent())
    user_env <- if (identical(caller, add_benefits) || identical(caller, add_losses)) {
      parent.frame(2)
    } else {
      parent.frame()
    }
    lifecycle::deprecate_warn(
      "1.3.0", I("The legacy effects interface of `add_effects()`"),
      details = paste(
        "The legacy effects syntax will be removed in a future version of multiscape.",
        "Use exactly one of effect, outcome, or relative_change in effects tables,",
        "and raster_aggregation/raster_type for raster inputs.",
        "Legacy calls retain their existing behavior."
      ),
      id = "multiscape-add-effects-legacy",
      user_env = user_env
    )
  }
  if (!legacy_aggregation) effect_aggregation <- match.arg(raster_aggregation)
  if (!legacy_type && is.list(effects) && !is.data.frame(effects)) {
    effect_type <- if (match.arg(raster_type) == "outcome") "after" else "delta"
  }

  effect_type <- match.arg(effect_type)
  effect_aggregation <- match.arg(effect_aggregation)
  component <- match.arg(component)

  # ---- checks: x
  assertthat::assert_that(!is.null(x), msg = "x is NULL")
  assertthat::assert_that(!is.null(x$data), msg = "x does not look like a multiscape Problem object")
  assertthat::assert_that(
    !is.null(x$data$pu), !is.null(x$data$features), !is.null(x$data$dist_features),
    msg = "x must be created with create_problem()"
  )
  assertthat::assert_that(!is.null(x$data$dist_actions), msg = "No actions found. Run add_actions() first.")

  # Serialization cannot copy terra's external pointer. This template is read
  # only during extraction; preserve its valid handle while cloning tabular data.
  pu_raster_id <- x$data$pu_raster_id
  x <- .pa_clone_data(x)
  if (inherits(pu_raster_id, "SpatRaster")) x$data$pu_raster_id <- pu_raster_id

  joint_context <- .pa_joint_effects_input(
    x, effects, !legacy_type && !legacy_component && !legacy_aggregation &&
      !length(legacy_columns) && !legacy_raster
  )
  if (!is.null(joint_context)) x <- joint_context$problem

  pu    <- x$data$pu
  feats <- x$data$features
  df    <- x$data$dist_features
  da    <- x$data$dist_actions
  acts  <- x$data$actions

  # required columns
  assertthat::assert_that(all(c("id", "internal_id") %in% names(pu)))
  assertthat::assert_that(all(c("id", "internal_id") %in% names(feats)))
  assertthat::assert_that(all(c("id") %in% names(acts)))
  assertthat::assert_that(all(c("pu", "feature", "amount") %in% names(df)))
  assertthat::assert_that(all(c("pu", "action", "cost") %in% names(da)))

  # defensive: enforce action internal_id
  if (!("internal_id" %in% names(acts))) {
    acts$internal_id <- seq_len(nrow(acts))
    x$data$actions <- acts
    acts <- x$data$actions
  }

  # ---- defensive coercions
  pu$id <- as.integer(pu$id)
  feats$id <- as.integer(feats$id)

  pu_ids <- pu$id
  feat_ids <- feats$id
  feat_names <- if ("name" %in% names(feats)) {
    as.character(feats$name)
  } else {
    paste0("feature.", feat_ids)
  }
  action_ids <- as.character(acts$id)

  # ---- helper: normalize feature column
  .normalize_feature <- function(feature_col, feats_df) {
    if (is.null(feature_col)) return(feature_col)

    if (is.factor(feature_col)) feature_col <- as.character(feature_col)

    if (is.character(feature_col)) {
      if (!("name" %in% names(feats_df))) {
        stop("features have no 'name' column, cannot match features by name.", call. = FALSE)
      }

      m <- match(feature_col, as.character(feats_df$name))
      bad <- unique(feature_col[is.na(m)])

      if (length(bad) > 0) {
        stop(
          "Unknown feature name(s) in effects$feature: ",
          paste0("'", bad, "'", collapse = ", "),
          ". Valid names are: ",
          paste0("'", as.character(feats_df$name), "'", collapse = ", "),
          call. = FALSE
        )
      }

      return(as.integer(feats_df$id[m]))
    }

    if (is.numeric(feature_col) || is.integer(feature_col)) {
      feature_col <- as.integer(feature_col)
      bad <- unique(feature_col[!feature_col %in% feats_df$id])

      if (length(bad) > 0) {
        stop(
          "Unknown feature id(s) in effects$feature: ",
          paste(bad, collapse = ", "),
          ". Valid ids are: ",
          paste(feats_df$id, collapse = ", "),
          call. = FALSE
        )
      }

      return(feature_col)
    }

    stop("effects$feature must be either numeric ids or character feature names.", call. = FALSE)
  }


  # ---- helper: validate numeric effect columns
  .validate_effect_values <- function(tbl, columns, context = "effects") {
    columns <- intersect(columns, names(tbl))

    if (length(columns) == 0L) {
      return(invisible(TRUE))
    }

    for (nm in columns) {
      values <- tbl[[nm]]

      if (!is.numeric(values)) {
        stop(
          context,
          ": column '",
          nm,
          "' must be numeric.",
          call. = FALSE
        )
      }

      if (anyNA(values)) {
        stop(
          context,
          ": column '",
          nm,
          "' must not contain missing values.",
          call. = FALSE
        )
      }

      if (any(!is.finite(values))) {
        stop(
          context,
          ": column '",
          nm,
          "' must contain only finite values.",
          call. = FALSE
        )
      }
    }

    invisible(TRUE)
  }

  # ---- helper: reject duplicated effect keys
  .validate_effect_keys <- function(tbl, keys, context = "effects") {
    keys <- intersect(keys, names(tbl))

    if (length(keys) == 0L || nrow(tbl) == 0L) {
      return(invisible(TRUE))
    }

    duplicated_key <- duplicated(tbl[, keys, drop = FALSE])

    if (any(duplicated_key)) {
      first_duplicate <- tbl[
        which(duplicated_key)[1L],
        keys,
        drop = FALSE
      ]

      example <- paste(
        paste0(
          names(first_duplicate),
          "=",
          vapply(
            first_duplicate,
            as.character,
            character(1)
          )
        ),
        collapse = ", "
      )

      stop(
        context,
        " contains duplicated combination(s) of ",
        paste(keys, collapse = ", "),
        ". Example: ",
        example,
        ".",
        call. = FALSE
      )
    }

    invisible(TRUE)
  }

  # ---- baseline lookup for (pu, feature) -> amount
  df$pu <- as.integer(df$pu)
  df$feature <- as.integer(df$feature)
  df$amount <- as.numeric(df$amount)

  if (anyNA(df$amount) || any(!is.finite(df$amount))) {
    stop(
      "x$data$dist_features$amount must contain only finite, non-missing values.",
      call. = FALSE
    )
  }

  base_key <- paste(df$pu, df$feature, sep = "||")
  base_amt <- df$amount
  names(base_amt) <- base_key

  .baseline_amount <- function(pu_vec, feat_vec) {
    k <- paste(as.integer(pu_vec), as.integer(feat_vec), sep = "||")
    out <- unname(base_amt[k])
    out[is.na(out)] <- 0
    out
  }

  # ---- helper: split signed delta into benefit/loss
  .split_delta <- function(delta) {
    delta <- as.numeric(delta)

    if (anyNA(delta) || any(!is.finite(delta))) {
      stop(
        "Signed effect values must contain only finite, non-missing values.",
        call. = FALSE
      )
    }

    list(
      benefit = pmax(delta, 0),
      loss = pmax(-delta, 0)
    )
  }

  # ---- helper: compute amount_after from signed delta
  .amount_after_from_delta <- function(pu_vec, feat_vec, delta_vec) {
    delta_vec <- as.numeric(delta_vec)

    if (anyNA(delta_vec) || any(!is.finite(delta_vec))) {
      stop(
        "Signed effect values must contain only finite, non-missing values.",
        call. = FALSE
      )
    }

    if (length(delta_vec) == 0) {
      return(numeric(0))
    }

    baseline <- .baseline_amount(pu_vec, feat_vec)

    if (length(baseline) != length(delta_vec)) {
      stop(
        "Internal error: baseline and delta lengths differ while computing amount_after.",
        call. = FALSE
      )
    }

    out <- baseline + delta_vec
    out[is.na(out)] <- 0
    out
  }

  # ---- helper: validate split effects
  .validate_split_effects <- function(tbl, context = "effects") {
    if (!("benefit" %in% names(tbl)) || !("loss" %in% names(tbl))) {
      stop(
        "Internal error: .validate_split_effects() requires 'benefit' and 'loss' columns.",
        call. = FALSE
      )
    }

    if (!is.numeric(tbl$benefit) || !is.numeric(tbl$loss)) {
      stop(
        context,
        ": 'benefit' and 'loss' must be numeric.",
        call. = FALSE
      )
    }

    tbl$benefit <- as.numeric(tbl$benefit)
    tbl$loss <- as.numeric(tbl$loss)

    if (
      anyNA(tbl$benefit) ||
      anyNA(tbl$loss) ||
      any(!is.finite(tbl$benefit)) ||
      any(!is.finite(tbl$loss))
    ) {
      stop(
        context,
        ": 'benefit' and 'loss' must contain only finite, non-missing values.",
        call. = FALSE
      )
    }

    if (any(tbl$benefit < 0) || any(tbl$loss < 0)) {
      stop(
        context,
        ": 'benefit' and 'loss' must be non-negative.",
        call. = FALSE
      )
    }

    bad <- which(tbl$benefit > 0 & tbl$loss > 0)

    if (length(bad) > 0) {
      ex <- tbl[
        bad[1],
        intersect(c("pu", "action", "feature", "benefit", "loss"), names(tbl)),
        drop = FALSE
      ]

      msg <- paste0(
        context,
        ": a single (pu, action, feature) effect cannot have both positive ",
        "'benefit' and positive 'loss'."
      )

      if (nrow(ex) == 1) {
        msg <- paste0(
          msg,
          " Example offending row -> pu=", ex$pu,
          ", action='", ex$action,
          "', feature=", ex$feature,
          ", benefit=", ex$benefit,
          ", loss=", ex$loss, "."
        )
      }

      stop(msg, call. = FALSE)
    }

    tbl
  }

  # ---- drop locked-out actions
  if ("status" %in% names(da)) {
    da <- da[da$status != 3L, , drop = FALSE]
    if (nrow(da) == 0) {
      stop("All (pu, action) pairs are locked_out (status=3).", call. = FALSE)
    }
  }

  # ---- helper: align raster to a template
  .align_to <- function(r, template) {
    if (!is.na(terra::crs(r)) &&
        !is.na(terra::crs(template)) &&
        terra::crs(r) != terra::crs(template)) {
      r <- terra::project(r, template)
    }

    if (!terra::compareGeom(r, template, stopOnError = FALSE)) {
      r <- terra::resample(r, template)
    }

    r
  }

  # ---- helper: build effects from rasters
  .effects_from_rasters <- function(x, effects_list) {
    if (!requireNamespace("terra", quietly = TRUE)) {
      stop("Raster effects require the 'terra' package.", call. = FALSE)
    }

    has_pu_raster <- !is.null(x$data$pu_raster_id) &&
      inherits(x$data$pu_raster_id, "SpatRaster")
    has_pu_sf <- !is.null(x$data$pu_sf) &&
      inherits(x$data$pu_sf, "sf")

    if (!has_pu_raster && !has_pu_sf) {
      stop(
        "To use raster effects, the object must contain either ",
        "x$data$pu_raster_id (SpatRaster) or x$data$pu_sf (sf).",
        call. = FALSE
      )
    }

    if (is.null(names(effects_list)) || any(names(effects_list) == "")) {
      stop(
        "If effects is a list of rasters, it must be a named list with names = action ids.",
        call. = FALSE
      )
    }

    if (!all(names(effects_list) %in% action_ids)) {
      bad <- setdiff(names(effects_list), action_ids)
      stop("effects list contains unknown action ids: ", paste(bad, collapse = ", "), call. = FALSE)
    }

    baseline_mat <- matrix(0, nrow = length(pu_ids), ncol = length(feat_ids))
    pu_pos <- match(df$pu, pu_ids)
    ft_pos <- match(df$feature, feat_ids)
    ok <- !(is.na(pu_pos) | is.na(ft_pos))

    if (any(ok)) {
      idx <- (ft_pos[ok] - 1L) * length(pu_ids) + pu_pos[ok]
      baseline_mat[idx] <- df$amount[ok]
    }

    out_list <- vector("list", length(effects_list))
    k <- 0L

    for (a in names(effects_list)) {
      r <- effects_list[[a]]

      if (is.null(r)) next

      if (!inherits(r, "SpatRaster")) {
        stop("effects[['", a, "']] must be a terra::SpatRaster.", call. = FALSE)
      }

      if (terra::nlyr(r) != nrow(feats)) {
        stop(
          "effects[['", a, "']] has ", terra::nlyr(r),
          " layers but x$data$features has ", nrow(feats),
          " features. Provide one layer per feature.",
          call. = FALSE
        )
      }

      try(names(r) <- feat_names, silent = TRUE)

      if (has_pu_raster) {
        z <- x$data$pu_raster_id
        r2 <- .align_to(r, z)
        zb <- terra::zonal(r2, z, fun = effect_aggregation, na.rm = TRUE)
        zb <- zb[match(pu_ids, zb[[1]]), , drop = FALSE]
        mat <- as.matrix(zb[, -1, drop = FALSE])
      } else {
        pu_sf <- x$data$pu_sf
        pu_v <- terra::vect(pu_sf)

        fun <- switch(
          effect_aggregation,
          sum = function(v, ...) sum(v, na.rm = TRUE),
          mean = function(v, ...) mean(v, na.rm = TRUE)
        )

        ex <- terra::extract(r, pu_v, fun = fun, na.rm = TRUE)
        # terra::extract returns polygon row numbers, not external PU IDs.
        polygon_rows <- if (legacy_type || legacy_raster) pu_ids else seq_along(pu_ids)
        ex <- ex[match(polygon_rows, ex[[1]]), , drop = FALSE]
        mat <- as.matrix(ex[, -1, drop = FALSE])
      }

      if (identical(effect_type, "after")) {
        amount_after_mat <- mat
        delta_mat <- mat - baseline_mat
      } else {
        delta_mat <- mat
        amount_after_mat <- baseline_mat + delta_mat
      }

      # Feature-major ordering matches the pu/feature keys below. Keep the
      # historical ordering for explicitly requested legacy raster calls.
      delta_vec <- if (legacy_type || legacy_raster) as.vector(t(delta_mat)) else as.vector(delta_mat)
      delta_vec[is.na(delta_vec)] <- 0

      amount_after_vec <- if (legacy_type || legacy_raster) as.vector(t(amount_after_mat)) else as.vector(amount_after_mat)
      amount_after_vec[is.na(amount_after_vec)] <- 0

      sp <- .split_delta(delta_vec)

      k <- k + 1L
      out_list[[k]] <- data.frame(
        pu = rep(pu_ids, times = ncol(delta_mat)),
        action = rep(a, times = length(pu_ids) * ncol(delta_mat)),
        feature = rep(feat_ids, each = length(pu_ids)),
        amount_after = amount_after_vec,
        benefit = sp$benefit,
        loss = sp$loss,
        stringsAsFactors = FALSE
      )
    }

    out_list <- out_list[seq_len(k)]
    out <- dplyr::bind_rows(out_list)

    out <- dplyr::inner_join(
      out,
      da[, c("pu", "action"), drop = FALSE],
      by = c("pu", "action")
    )

    out
  }

  # ---- compute effects
  if (is.list(effects) && !inherits(effects, "data.frame")) {

    base <- .effects_from_rasters(x, effects)

  } else if (is.null(effects)) {

    base <- da[0, c("pu", "action"), drop = FALSE]
    base$feature <- integer(0)
    base$amount_after <- numeric(0)
    base$benefit <- numeric(0)
    base$loss <- numeric(0)

  } else if (inherits(effects, "data.frame")) {

    b <- effects

    if ("id" %in% names(b) && !("action" %in% names(b))) {
      names(b)[names(b) == "id"] <- "action"
    }

    if ("action" %in% names(b)) {
      b$action <- as.character(b$action)
    }

    if ("feature" %in% names(b)) {
      b$feature <- .normalize_feature(b$feature, feats)
    }

    # Semantic inputs are converted once to signed changes. Existing model
    # builders continue to consume the same canonical effect coefficients.
    if (length(semantic_columns) == 1L && length(legacy_columns) == 0L && !legacy_type) {
      source <- semantic_columns[[1L]]
      assertthat::assert_that(all(c("action", "feature") %in% names(b)))
      .validate_effect_values(b, source)
      .validate_effect_keys(b, intersect(c("pu", "action", "feature"), names(b)))
      if (!all(b$action %in% action_ids)) stop("Unknown action id(s) in effects.", call. = FALSE)
      if (!("pu" %in% names(b))) {
        b <- dplyr::inner_join(da[, c("pu", "action"), drop = FALSE], b,
                              by = "action", relationship = "many-to-many")
      }
      reference <- .baseline_amount(b$pu, b$feature)
      value <- b[[source]]
      delta <- switch(source, effect = value, outcome = value - reference,
                      relative_change = reference * value)
      b[[source]] <- NULL
      b$delta <- delta
      effect_type <- "delta"
    }

    # ------------------------------------------------------------------
    # Case A: compact multiplier table: action, feature, multiplier
    # ------------------------------------------------------------------
    if (all(c("action", "feature", "multiplier") %in% names(b)) &&
        !("pu" %in% names(b)) &&
        !any(c("delta", "effect", "benefit", "loss", "after") %in% names(b))) {

      .validate_effect_keys(
        b,
        keys = c("action", "feature"),
        context = "Compact multiplier effects"
      )

      .validate_effect_values(
        b,
        columns = "multiplier",
        context = "Compact multiplier effects"
      )

      b$multiplier <- as.numeric(b$multiplier)

      assertthat::assert_that(
        assertthat::noNA(b$action),
        assertthat::noNA(b$feature)
      )
      assertthat::assert_that(all(b$action %in% action_ids), msg = "Unknown action id(s) in effects.")
      assertthat::assert_that(all(b$feature %in% feat_ids), msg = "Unknown feature id(s) in effects.")

      df2 <- df[, c("pu", "feature", "amount"), drop = FALSE]

      tmp <- dplyr::inner_join(
        da[, c("pu", "action"), drop = FALSE],
        df2,
        by = "pu",
        relationship = "many-to-many"
      )

      if (nrow(tmp) == 0) {
        stop("No (pu, action, feature) triples were created. Check dist_actions/dist_features.", call. = FALSE)
      }

      tmp <- dplyr::left_join(tmp, b, by = c("action", "feature"))
      tmp$multiplier[is.na(tmp$multiplier)] <- 0

      amount <- as.numeric(tmp$amount)
      multiplier <- as.numeric(tmp$multiplier)

      if (identical(effect_type, "after")) {
        amount_after <- amount * multiplier
        delta <- amount_after - amount
      } else {
        delta <- amount * multiplier
        amount_after <- amount + delta
      }

      amount_after[is.na(amount_after)] <- 0
      delta[is.na(delta)] <- 0

      if (length(delta) != nrow(tmp) || length(amount_after) != nrow(tmp)) {
        stop(
          "Internal error while computing multiplier effects: computed vectors do not match effect rows.",
          call. = FALSE
        )
      }

      sp <- .split_delta(delta)

      base <- tmp[, c("pu", "action", "feature")]
      base$amount_after <- amount_after
      base$benefit <- sp$benefit
      base$loss <- sp$loss

    } else {

      # ----------------------------------------------------------------
      # Case B: explicit table: pu, action, feature, ...
      # ----------------------------------------------------------------
      assertthat::assert_that(all(c("pu", "action", "feature") %in% names(b)))

      b$pu <- as.integer(b$pu)
      b$feature <- as.integer(b$feature)

      assertthat::assert_that(
        assertthat::noNA(b$pu),
        assertthat::noNA(b$action),
        assertthat::noNA(b$feature)
      )
      assertthat::assert_that(all(b$pu %in% pu_ids), msg = "Unknown pu id(s) in effects.")
      assertthat::assert_that(all(b$action %in% action_ids), msg = "Unknown action id(s) in effects.")
      assertthat::assert_that(all(b$feature %in% feat_ids), msg = "Unknown feature id(s) in effects.")

      .validate_effect_keys(
        b,
        keys = c("pu", "action", "feature"),
        context = "Explicit effects"
      )

      tmp <- dplyr::inner_join(
        b,
        da[, c("pu", "action"), drop = FALSE],
        by = c("pu", "action")
      )

      if (nrow(tmp) == 0) {
        stop("No rows in effects match feasible (pu, action) pairs.", call. = FALSE)
      }

      has_any_split <- any(c("benefit", "loss") %in% names(tmp))

      # --------------------------------------------------------------
      # Case B1: explicit non-negative split benefit/loss
      # --------------------------------------------------------------
      if (has_any_split &&
          !("delta" %in% names(tmp)) &&
          !("effect" %in% names(tmp)) &&
          !("after" %in% names(tmp))) {

        if (!("benefit" %in% names(tmp))) tmp$benefit <- 0
        if (!("loss" %in% names(tmp))) tmp$loss <- 0

        .validate_effect_values(
          tmp,
          columns = c("benefit", "loss"),
          context = "Explicit benefit/loss effects"
        )

        tmp <- .validate_split_effects(
          tmp,
          context = "When providing explicit benefit/loss columns"
        )

        delta <- as.numeric(tmp$benefit) - as.numeric(tmp$loss)

        tmp$amount_after <- .amount_after_from_delta(
          pu_vec = tmp$pu,
          feat_vec = tmp$feature,
          delta_vec = delta
        )

        base <- tmp[, c("pu", "action", "feature", "amount_after", "benefit", "loss")]

      } else {

        # ------------------------------------------------------------
        # Case B2: signed input: delta/effect/after/legacy benefit
        # ------------------------------------------------------------
        has_delta <- "delta" %in% names(tmp)
        has_effect <- "effect" %in% names(tmp)
        has_after <- "after" %in% names(tmp)
        has_legacy_benefit <- "benefit" %in% names(tmp) && !("loss" %in% names(tmp))

        n_signed_sources <- sum(c(
          has_delta,
          has_effect,
          has_after,
          has_legacy_benefit
        ))

        if (n_signed_sources == 0) {
          stop(
            "effects data.frame must include 'delta', 'effect', 'after', ",
            "or legacy signed 'benefit' without 'loss', or explicit non-negative ",
            "'benefit/loss' columns.",
            call. = FALSE
          )
        }

        if (n_signed_sources > 1) {
          stop(
            "Ambiguous effect specification: provide only one of 'delta', ",
            "'effect', 'after', or legacy signed 'benefit' without 'loss'.",
            call. = FALSE
          )
        }

        signed_column <- if (has_after) {
          "after"
        } else if (has_delta) {
          "delta"
        } else if (has_effect) {
          "effect"
        } else {
          "benefit"
        }

        .validate_effect_values(
          tmp,
          columns = signed_column,
          context = "Signed effects"
        )

        base_amount <- .baseline_amount(tmp$pu, tmp$feature)

        if (has_after) {
          if (!identical(effect_type, "after")) {
            stop(
              "Column 'after' was provided, but effect_type = 'delta'. ",
              "Use effect_type = 'after', or rename the column to 'delta' if ",
              "values are signed net changes.",
              call. = FALSE
            )
          }

          tmp$amount_after <- as.numeric(tmp$after)
          tmp$delta <- tmp$amount_after - base_amount

        } else if (has_delta) {
          if (identical(effect_type, "after")) {
            stop(
              "Column 'delta' was provided, but effect_type = 'after'. ",
              "Use effect_type = 'delta', or provide an 'after' column if ",
              "values are after-action amounts.",
              call. = FALSE
            )
          }

          tmp$delta <- as.numeric(tmp$delta)
          tmp$amount_after <- base_amount + tmp$delta

        } else if (has_effect) {
          tmp$effect <- as.numeric(tmp$effect)

          if (identical(effect_type, "after")) {
            tmp$amount_after <- tmp$effect
            tmp$delta <- tmp$amount_after - base_amount
          } else {
            tmp$delta <- tmp$effect
            tmp$amount_after <- base_amount + tmp$delta
          }

        } else if (has_legacy_benefit) {
          tmp$benefit <- as.numeric(tmp$benefit)

          if (identical(effect_type, "after")) {
            tmp$amount_after <- tmp$benefit
            tmp$delta <- tmp$amount_after - base_amount
          } else {
            tmp$delta <- tmp$benefit
            tmp$amount_after <- base_amount + tmp$delta
          }
        }

        tmp$delta <- as.numeric(tmp$delta)
        tmp$amount_after <- as.numeric(tmp$amount_after)

        if (
          anyNA(tmp$delta) ||
          anyNA(tmp$amount_after) ||
          any(!is.finite(tmp$delta)) ||
          any(!is.finite(tmp$amount_after))
        ) {
          stop(
            "Computed effect values must contain only finite, non-missing values.",
            call. = FALSE
          )
        }

        if (length(tmp$delta) != nrow(tmp)) {
          stop(
            "Internal error while computing effects: 'delta' length does not match number of effect rows.",
            call. = FALSE
          )
        }

        if (length(tmp$amount_after) != nrow(tmp)) {
          stop(
            "Internal error while computing effects: 'amount_after' length does not match number of effect rows.",
            call. = FALSE
          )
        }

        sp <- .split_delta(tmp$delta)

        base <- tmp[, c("pu", "action", "feature")]
        base$amount_after <- tmp$amount_after
        base$benefit <- sp$benefit
        base$loss <- sp$loss
      }
    }

  } else {
    stop(
      "Unsupported type for 'effects'. Use NULL, a data.frame, or a named list of SpatRaster.",
      call. = FALSE
    )
  }

  # ---- defensively aggregate internally generated duplicate rows
  if (nrow(base) > 0) {
    base <- stats::aggregate(
      cbind(benefit, loss) ~ pu + action + feature,
      data = base,
      FUN = sum
    )

    delta <- as.numeric(base$benefit) - as.numeric(base$loss)

    base$amount_after <- .amount_after_from_delta(
      pu_vec = base$pu,
      feat_vec = base$feature,
      delta_vec = delta
    )

    base <- base[, c("pu", "action", "feature", "amount_after", "benefit", "loss")]
  }

  # ---- cleanup / validation / filtering
  base$pu <- as.integer(base$pu)
  base$feature <- as.integer(base$feature)

  if (!("amount_after" %in% names(base))) {
    delta <- as.numeric(base$benefit) - as.numeric(base$loss)

    base$amount_after <- .amount_after_from_delta(
      pu_vec = base$pu,
      feat_vec = base$feature,
      delta_vec = delta
    )
  }

  base$amount_after <- as.numeric(base$amount_after)
  base$benefit <- as.numeric(base$benefit)
  base$loss <- as.numeric(base$loss)

  if (
    anyNA(base$amount_after) ||
    anyNA(base$benefit) ||
    anyNA(base$loss) ||
    any(!is.finite(base$amount_after)) ||
    any(!is.finite(base$benefit)) ||
    any(!is.finite(base$loss))
  ) {
    stop(
      "Validated effects must contain only finite, non-missing values.",
      call. = FALSE
    )
  }

  if (any(base$amount_after < 0)) {
    stop(
      "Some after-action feature amounts are negative. Check effects, losses, or multipliers.",
      call. = FALSE
    )
  }

  base <- .validate_split_effects(base, context = "Validated effects")

  if (identical(component, "benefit")) {
    base <- base[base$benefit > 0, , drop = FALSE]
  }

  if (identical(component, "loss")) {
    base <- base[base$loss > 0, , drop = FALSE]
  }

  if (nrow(base) == 0 && !is.null(effects)) {
    warning(
      "No effect rows remain after component filtering.",
      call. = FALSE,
      immediate. = TRUE
    )
  }

  # ---- add internal ids
  pu_map <- pu[, c("id", "internal_id")]
  feats_map <- feats[, c("id", "internal_id")]
  acts_map <- x$data$actions[, c("id", "internal_id")]

  base$internal_pu <- pu_map$internal_id[match(base$pu, pu_map$id)]
  base$internal_feature <- feats_map$internal_id[match(base$feature, feats_map$id)]
  base$internal_action <- acts_map$internal_id[match(base$action, acts_map$id)]

  dist_effects <- base[, c(
    "pu", "action", "feature",
    "amount_after", "benefit", "loss",
    "internal_pu", "internal_action", "internal_feature"
  ), drop = FALSE]

  dist_effects <- .pa_add_feature_labels(
    df = dist_effects,
    features_df = feats,
    feature_col = "feature",
    internal_feature_col = "internal_feature",
    out_col = "feature_name"
  )

  dist_effects <- .pa_add_action_labels(
    df = dist_effects,
    actions_df = acts,
    action_col = "action",
    internal_action_col = "internal_action",
    out_col = "action_name"
  )

  dist_effects$reference_amount <- .baseline_amount(dist_effects$pu, dist_effects$feature)
  dist_effects$action_outcome <- dist_effects$amount_after
  dist_effects$effect <- dist_effects$benefit - dist_effects$loss
  x$data$dist_effects <- dist_effects

  x$data$effects_meta <- list(
    stored_as = "amount_after_benefit_loss",
    input_interpretation = effect_type,
    input_specification = if (length(semantic_columns) && !legacy_type) {
      semantic_columns[[1L]]
    } else if (is.list(effects) && !is.data.frame(effects) &&
               !legacy_type && !legacy_raster && !is.null(effects)) {
      if (effect_type == "after") "raster_outcome" else "raster_effect"
    } else {
      effect_type
    },
    component = component,
    amount_after = "baseline + benefit - loss"
  )

  if (!is.null(joint_context)) x <- .pa_finish_joint_effects(x, joint_context)
  x
}


#' @title Add benefits
#'
#' @description
#' Convenience wrapper around \code{\link{add_effects}} that keeps only positive
#' effects, that is, rows with \code{benefit > 0}.
#' Effects share a single definition with \code{add_effects()} and
#' \code{add_losses()}; a second definition raises an error.
#'
#' @inheritParams add_effects
#' @param benefits Alias of \code{effects}, kept for backwards compatibility.
#'
#' @return An updated \code{Problem} object containing:
#' \describe{
#'   \item{\code{dist_effects}}{The canonical filtered effects table, containing
#'   only rows with \code{benefit > 0}.}
#'   \item{\code{dist_benefit}}{A backwards-compatible mirror table containing
#'   only the benefit component.}
#' }
#'
#' @seealso
#' \code{\link{add_effects}},
#' \code{\link{add_losses}},
#' \code{\link{add_objective_max_benefit}}
#'
#' @export
add_benefits <- function(
    x,
    benefits = NULL,
    effect_type = c("delta", "after"),
    effect_aggregation = c("sum", "mean")
) {
  effects <- benefits

  x <- add_effects(
    x = x,
    effects = effects,
    effect_type = effect_type,
    effect_aggregation = effect_aggregation,
    component = "benefit"
  )

  if (!is.null(x$data$dist_effects) &&
      inherits(x$data$dist_effects, "data.frame")) {
    db <- x$data$dist_effects

    if ("loss" %in% names(db)) {
      db$loss <- NULL
    }

    x$data$dist_benefit <- db
  } else {
    x$data$dist_benefit <- x$data$dist_effects
  }

  x
}


#' @title Add losses
#'
#' @description
#' Convenience wrapper around \code{\link{add_effects}} that keeps only negative
#' effects, represented by rows with \code{loss > 0}.
#' Effects share a single definition with \code{add_effects()} and
#' \code{add_benefits()}; a second definition raises an error.
#'
#' @inheritParams add_effects
#' @param losses Alias of \code{effects}, used for symmetry with
#'   \code{add_benefits()}.
#'
#' @return An updated \code{Problem} object containing:
#' \describe{
#'   \item{\code{dist_effects}}{The canonical filtered effects table,
#'   containing only rows with \code{loss > 0}.}
#'   \item{\code{dist_loss}}{A convenience table containing only the loss
#'   component.}
#'   \item{\code{losses_meta}}{Metadata for the stored loss table.}
#' }
#'
#' @seealso
#' \code{\link{add_effects}},
#' \code{\link{add_benefits}},
#' \code{\link{add_objective_min_loss}}
#'
#' @export
add_losses <- function(
    x,
    losses = NULL,
    effect_type = c("delta", "after"),
    effect_aggregation = c("sum", "mean")
) {
  effects <- losses

  x <- add_effects(
    x = x,
    effects = effects,
    effect_type = effect_type,
    effect_aggregation = effect_aggregation,
    component = "loss"
  )

  if (!is.null(x$data$dist_effects) &&
      inherits(x$data$dist_effects, "data.frame")) {
    dl <- x$data$dist_effects

    if ("benefit" %in% names(dl)) {
      dl$benefit <- NULL
    }

    x$data$dist_loss <- dl
    x$data$losses_meta <- list(
      stored_as = "loss",
      input_interpretation = x$data$effects_meta$input_interpretation
    )
  }

  x
}

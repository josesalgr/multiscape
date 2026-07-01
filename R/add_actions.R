#' @include internal.R
#'
#' @title Add management actions to a planning problem
#'
#' @description
#' Define the action catalogue, the set of feasible planning unit--action pairs,
#' their implementation costs, and the effective area represented by each
#' feasible planning unit--action decision.
#'
#' This function adds two core components to a \code{Problem} object. First, it
#' stores the action catalogue. Second, it creates the feasible planning
#' unit--action table, including implementation costs, effective action areas,
#' status codes, and internal indices used by the optimization backend.
#'
#' Conceptually, if \eqn{\mathcal{I}} is the set of planning units and
#' \eqn{\mathcal{A}} is the set of actions, this function determines which
#' pairs \eqn{(i,a) \in \mathcal{I} \times \mathcal{A}} are feasible decisions
#' and assigns a non-negative implementation cost to each feasible pair.
#'
#' @details
#' \strong{When to use \code{add_actions()}.}
#'
#' Use this function when you want to move from a planning problem defined only
#' by planning units and features to a problem in which decisions are explicitly
#' represented as actions applied in planning units.
#'
#' \strong{Action catalogue.}
#'
#' The \code{actions} argument must be a \code{data.frame} with a unique
#' \code{id} column identifying each action. If a column named \code{action} is
#' supplied instead, it is renamed internally to \code{id}. Additional columns
#' are preserved. If no \code{name} column is provided, action labels are taken
#' from \code{id}. If an \code{action_set} column is present, it is also
#' preserved and can later be used to refer to groups of actions.
#'
#' Actions are stored sorted by \code{id} to ensure reproducible internal
#' indexing.
#'
#' \strong{Feasible planning unit--action pairs.}
#'
#' Feasibility is controlled through \code{include_pairs} and
#' \code{exclude_pairs}.
#'
#' If \code{include_pairs = NULL}, all possible \code{(pu, action)} pairs are
#' initially considered feasible, that is, all pairs
#' \eqn{(i,a) \in \mathcal{I} \times \mathcal{A}}.
#'
#' If \code{include_pairs} is supplied, only those pairs are retained. If
#' \code{exclude_pairs} is also supplied, matching pairs are removed
#' afterwards.
#'
#' More precisely, let \eqn{\mathcal{D}^{\mathrm{inc}}} denote the set of
#' included planning unit--action pairs and let
#' \eqn{\mathcal{D}^{\mathrm{exc}}} denote the set of excluded pairs.
#'
#' If \code{include_pairs = NULL}, the feasible decision set is:
#' \deqn{
#' \{(i,a) : i \in \mathcal{I},\ a \in \mathcal{A}\} \setminus \mathcal{D}^{\mathrm{exc}}.
#' }
#'
#' If \code{include_pairs} is supplied, the feasible decision set is:
#' \deqn{
#' \mathcal{D}^{\mathrm{inc}} \setminus \mathcal{D}^{\mathrm{exc}}.
#' }
#'
#' Both \code{include_pairs} and \code{exclude_pairs} can be specified as:
#' \itemize{
#'   \item \code{NULL},
#'   \item a \code{data.frame} with columns \code{pu} and \code{action},
#'   \item or a named list whose names are action ids.
#' }
#'
#' When supplied as a \code{data.frame}, the object must contain columns
#' \code{pu} and \code{action}. An optional logical-like column
#' \code{feasible} may also be provided; only rows with \code{feasible = TRUE}
#' are retained. Missing values in \code{feasible} are treated as
#' \code{FALSE}.
#'
#' When supplied as a named list, names must match action ids. Each element may
#' contain either:
#' \itemize{
#'   \item a vector of planning-unit ids, or
#'   \item an \code{sf} object defining the spatial zone where the action is
#'   feasible.
#' }
#'
#' Lists may mix vectors of planning-unit ids and \code{sf} objects across
#' actions. In the spatial case, feasible planning units are identified using
#' \code{sf::st_intersects()} against the stored planning-unit geometry. If
#' \code{include_pairs} or \code{exclude_pairs} contains \code{sf} objects, the
#' problem must contain planning-unit geometry in \code{x$data$pu_sf}; otherwise
#' an error is raised.
#'
#' Spatial exclusions are applied after inclusions. If a planning unit--action
#' pair is included and excluded, the exclusion takes precedence and the pair is
#' removed. Spatial exclusions remove complete \code{(pu, action)} pairs; they
#' do not partially subtract area from included geometries.
#'
#' \strong{Action areas.}
#'
#' The \code{action_area} column in \code{dist_actions} stores the effective
#' area represented by each feasible \code{(pu, action)} decision. This is an
#' area, not an action intensity.
#'
#' If \code{action_area = NULL}, action areas are derived automatically:
#' \itemize{
#'   \item when \code{include_pairs} is supplied using \code{sf} objects, action
#'   areas are computed as the area of the spatial intersection between
#'   planning-unit geometries and the corresponding action geometries;
#'   \item when feasible pairs are supplied without spatial geometries, action
#'   areas default to the full planning-unit area when this can be derived from
#'   the problem object.
#' }
#'
#' If \code{action_area} is supplied as a \code{data.frame}, it must contain
#' columns \code{pu}, \code{action}, and \code{action_area}. A column named
#' \code{area} is also accepted and renamed internally to \code{action_area}.
#' Supplied areas must be finite and non-negative. User-supplied values override
#' automatically derived values for matching feasible pairs. Rows referring to
#' non-feasible pairs are ignored with a warning.
#'
#' If full planning-unit areas cannot be derived for some feasible pairs,
#' \code{action_area} is left as \code{NA} for those pairs. Area-based action
#' constraints should check for missing \code{action_area} values before model
#' construction.
#'
#' \strong{Feasibility versus decision fixing.}
#'
#' This function only determines whether a pair \eqn{(i,a)} exists in the model.
#' It does not force a feasible action to be selected or forbidden beyond
#' structural infeasibility. Fixed decisions should instead be imposed later
#' with \code{\link{add_constraint_locked_actions}}.
#'
#' \strong{Costs.}
#'
#' Costs can be supplied in several ways:
#' \itemize{
#'   \item If \code{cost = NULL}, all feasible pairs receive a default cost of
#'   \code{1}.
#'   \item If \code{cost} is a scalar, that value is assigned to all feasible
#'   pairs.
#'   \item If \code{cost} is a named numeric vector, names must match action ids
#'   and costs are assigned by action.
#'   \item If \code{cost} is a \code{data.frame}, it must define either:
#'   \itemize{
#'     \item action-level costs through columns \code{action} and \code{cost}, or
#'     \item pair-specific costs through columns \code{pu}, \code{action}, and
#'     \code{cost}.
#'   }
#' }
#'
#' In all cases, costs must be finite and non-negative.
#'
#' In practice, a scalar cost is useful when all actions cost the same
#' everywhere, a named vector is useful when cost depends only on action type,
#' and a \code{(pu, action, cost)} table is useful when cost varies by both
#' planning unit and action.
#'
#' \strong{Status values.}
#'
#' Internally, all feasible pairs are initialized with \code{status = 0},
#' meaning that the decision is free. If planning units have already been marked
#' as locked out, then all feasible actions in those planning units are assigned
#' \code{status = 3}. This preserves consistency with planning-unit exclusions
#' already stored in the problem.
#'
#' \strong{Replacement behaviour.}
#'
#' Calling \code{add_actions()} replaces any previous action catalogue and
#' feasible action table stored in the problem object.
#'
#' After defining actions, typical next steps include adding effects, optional
#' decision-fixing constraints, objectives, and solver settings before calling
#' \code{solve()}.
#'
#' @param x A \code{Problem} object created with \code{\link{create_problem}}.
#'
#' @param actions A \code{data.frame} defining the action catalogue. It must
#'   contain a unique \code{id} column. A column named \code{action} is also
#'   accepted and automatically renamed to \code{id}.
#'
#' @param include_pairs Optional specification of feasible \code{(pu, action)}
#'   pairs. It can be \code{NULL}, a \code{data.frame} with columns
#'   \code{pu} and \code{action} (optionally also \code{feasible}), or a named
#'   list whose names are action ids and whose elements are vectors of planning
#'   unit ids or \code{sf} objects.
#'
#' @param exclude_pairs Optional specification of infeasible \code{(pu, action)}
#'   pairs. It uses the same formats as \code{include_pairs} and removes
#'   matching pairs from the feasible set.
#'
#' @param cost Optional cost specification for feasible pairs. It may be
#'   \code{NULL}, a scalar numeric value, a named numeric vector indexed by
#'   action id, or a \code{data.frame} with columns \code{action, cost} or
#'   \code{pu, action, cost}.
#'
#' @param action_area Optional effective area specification for feasible
#'   \code{(pu, action)} pairs. It may be \code{NULL} or a \code{data.frame}
#'   with columns \code{pu}, \code{action}, and \code{action_area}. If
#'   \code{NULL}, action areas are derived from spatial \code{include_pairs}
#'   when available, otherwise they default to full planning-unit areas when
#'   these can be derived from the problem.
#'
#' @return An updated \code{Problem} object with:
#' \describe{
#'   \item{\code{actions}}{The action catalogue, including a unique integer
#'   \code{internal_id} for each action.}
#'   \item{\code{dist_actions}}{The feasible planning unit--action table with
#'   columns \code{pu}, \code{action}, \code{cost}, \code{action_area},
#'   \code{status}, \code{internal_pu}, and \code{internal_action}.}
#'   \item{\code{pu index}}{A mapping from user-supplied planning-unit ids to
#'   internal integer ids.}
#'   \item{\code{action index}}{A mapping from action ids to internal integer
#'   ids.}
#' }
#'
#' @seealso
#' \code{\link{create_problem}},
#' \code{\link{add_constraint_locked_actions}}
#'
#' @examples
#' # ------------------------------------------------------
#' # Minimal planning problem
#' # ------------------------------------------------------
#' pu <- data.frame(
#'   id = 1:4,
#'   cost = c(2, 3, 1, 4),
#'   area = c(100, 100, 100, 100)
#' )
#'
#' features <- data.frame(
#'   id = 1:2,
#'   name = c("sp1", "sp2")
#' )
#'
#' dist_features <- data.frame(
#'   pu = c(1, 1, 2, 3, 4, 4),
#'   feature = c(1, 2, 1, 2, 1, 2),
#'   amount = c(1, 2, 1, 3, 2, 1)
#' )
#'
#' p <- create_problem(
#'   pu = pu,
#'   features = features,
#'   dist_features = dist_features
#' )
#'
#' actions <- data.frame(
#'   id = c("conservation", "restoration"),
#'   name = c("Conservation", "Restoration")
#' )
#'
#' # Example 1: all actions feasible in all planning units
#' p1 <- add_actions(
#'   x = p,
#'   actions = actions,
#'   cost = c(conservation = 5, restoration = 12)
#' )
#'
#' print(p1)
#' utils::head(p1$data$dist_actions)
#'
#' # Example 2: specify feasible pairs explicitly
#' include_df <- data.frame(
#'   pu = c(1, 2, 3, 4),
#'   action = c("conservation", "conservation", "restoration", "restoration")
#' )
#'
#' p2 <- add_actions(
#'   x = p,
#'   actions = actions,
#'   include_pairs = include_df,
#'   cost = 10
#' )
#'
#' p2$data$dist_actions
#'
#' # Example 3: remove selected pairs after full expansion
#' exclude_df <- data.frame(
#'   pu = c(2, 4),
#'   action = c("restoration", "conservation")
#' )
#'
#' p3 <- add_actions(
#'   x = p,
#'   actions = actions,
#'   exclude_pairs = exclude_df,
#'   cost = c(conservation = 3, restoration = 8)
#' )
#'
#' p3$data$dist_actions
#'
#' # Example 4: provide action-specific areas manually
#' action_area <- data.frame(
#'   pu = c(1, 2, 3, 4),
#'   action = c("conservation", "conservation", "restoration", "restoration"),
#'   action_area = c(100, 50, 80, 100)
#' )
#'
#' p4 <- add_actions(
#'   x = p,
#'   actions = actions,
#'   include_pairs = include_df,
#'   action_area = action_area,
#'   cost = 10
#' )
#'
#' p4$data$dist_actions
#'
#' @export
add_actions <- function(
    x,
    actions,
    include_pairs = NULL,
    exclude_pairs = NULL,
    cost = NULL,
    action_area = NULL
) {

  .as_int_id <- function(v, what) {
    if (is.factor(v)) v <- as.character(v)
    if (is.character(v)) {
      if (any(grepl("[^0-9\\-]", v))) {
        stop(what, " must be numeric/integer ids (got non-numeric strings).", call. = FALSE)
      }
      v <- as.integer(v)
    } else {
      v <- as.integer(v)
    }
    if (anyNA(v)) stop(what, " contains NA after coercion to integer.", call. = FALSE)
    v
  }

  .normalize_feasible_col <- function(df, what) {
    if (!("feasible" %in% names(df))) {
      df$feasible <- TRUE
      return(df)
    }

    f <- df$feasible

    if (is.logical(f)) {
      # keep
    } else if (is.numeric(f) || is.integer(f)) {
      f <- f != 0
    } else if (is.factor(f)) {
      f <- as.character(f)
    }

    if (is.character(f)) {
      w <- tolower(trimws(f))
      f <- w %in% c("true", "t", "1", "yes", "y")
    } else {
      f <- as.logical(f)
    }

    f[is.na(f)] <- FALSE
    df$feasible <- as.logical(f)
    df
  }

  .empty_pairs <- function(with_area = FALSE) {
    if (isTRUE(with_area)) {
      data.frame(
        pu = integer(0),
        action = character(0),
        action_area = numeric(0),
        stringsAsFactors = FALSE
      )
    } else {
      data.frame(
        pu = integer(0),
        action = character(0),
        stringsAsFactors = FALSE
      )
    }
  }

  .check_spatial_ready <- function(what, pu_sf) {
    if (!requireNamespace("sf", quietly = TRUE)) {
      stop(what, " provided as sf layers requires the 'sf' package.", call. = FALSE)
    }

    if (is.null(pu_sf) || !inherits(pu_sf, "sf")) {
      stop(
        "To use '", what, "' as sf layers, the problem object must contain ",
        "x$data$pu_sf (sf planning unit geometry).",
        call. = FALSE
      )
    }

    if (!("id" %in% names(pu_sf))) {
      stop("x$data$pu_sf is missing an 'id' column.", call. = FALSE)
    }

    invisible(TRUE)
  }

  .align_zone_crs <- function(zone, pu_sf, what, action) {
    if (is.na(sf::st_crs(pu_sf)) || is.na(sf::st_crs(zone))) {
      warning(
        what, "[[", action, "]] or x$data$pu_sf has missing CRS; ",
        "spatial intersections and areas may be unreliable.",
        call. = FALSE,
        immediate. = TRUE
      )
      return(zone)
    }

    if (sf::st_crs(pu_sf) != sf::st_crs(zone)) {
      zone <- sf::st_transform(zone, sf::st_crs(pu_sf))
    }

    zone
  }

  .spatial_pairs <- function(
    pu_sf,
    zone,
    action,
    what,
    as_int_id_fun,
    compute_area = FALSE
  ) {
    if (!inherits(zone, "sf")) {
      stop(what, "[[", action, "]] must be an sf object.", call. = FALSE)
    }

    zone <- .align_zone_crs(zone, pu_sf, what, action)

    hits <- sf::st_intersects(pu_sf, zone, sparse = TRUE)
    idx <- which(lengths(hits) > 0L)

    if (length(idx) == 0L) {
      return(.empty_pairs(with_area = compute_area))
    }

    feasible_ids <- as_int_id_fun(
      pu_sf$id[idx],
      paste0(what, "$pu")
    )

    if (!isTRUE(compute_area)) {
      return(data.frame(
        pu = feasible_ids,
        action = action,
        stringsAsFactors = FALSE
      ))
    }

    pu_sub <- pu_sf[idx, , drop = FALSE]
    pu_sub$id <- as_int_id_fun(
      pu_sub$id,
      "x$data$pu_sf$id"
    )

    zone_union <- sf::st_union(sf::st_geometry(zone))
    zone_sf <- sf::st_sf(
      .zone_id = 1L,
      geometry = zone_union,
      crs = sf::st_crs(pu_sub)
    )

    inter <- suppressWarnings(
      sf::st_intersection(
        pu_sub[, "id", drop = FALSE],
        zone_sf
      )
    )

    if (nrow(inter) == 0L) {
      return(.empty_pairs(with_area = TRUE))
    }

    inter$id <- as_int_id_fun(
      inter$id,
      paste0(what, "$pu")
    )

    out <- data.frame(
      pu = inter$id,
      action = action,
      action_area = as.numeric(sf::st_area(inter)),
      stringsAsFactors = FALSE
    )

    out <- dplyr::group_by(
      out,
      .data$pu,
      .data$action
    )
    out <- dplyr::summarise(
      out,
      action_area = sum(.data$action_area, na.rm = TRUE),
      .groups = "drop"
    )
    out <- as.data.frame(out)

    out
  }

  .spec_to_pairs <- function(
    spec,
    what,
    action_ids,
    pu_ids,
    pu_sf,
    as_int_id_fun,
    compute_area = FALSE
  ) {
    if (is.null(spec)) return(NULL)

    if (inherits(spec, "data.frame")) {
      assertthat::assert_that(
        nrow(spec) > 0,
        msg = paste0(what, " is an empty data.frame.")
      )

      if ("id" %in% names(spec) && !("action" %in% names(spec))) {
        names(spec)[names(spec) == "id"] <- "action"
      }

      assertthat::assert_that(
        assertthat::has_name(spec, "pu"),
        assertthat::has_name(spec, "action"),
        msg = paste0(what, " must have columns 'pu' and 'action'.")
      )

      spec$pu <- as_int_id_fun(spec$pu, paste0(what, "$pu"))
      spec$action <- as.character(spec$action)
      spec <- .normalize_feasible_col(spec, what)

      if (!all(spec$pu %in% pu_ids)) {
        bad <- unique(spec$pu[!spec$pu %in% pu_ids])
        stop(
          what, " contains PU ids not present in x: ",
          paste(bad, collapse = ", "),
          call. = FALSE
        )
      }

      if (!all(spec$action %in% action_ids)) {
        bad <- unique(spec$action[!spec$action %in% action_ids])
        stop(
          what, " contains action ids not present in actions: ",
          paste(bad, collapse = ", "),
          call. = FALSE
        )
      }

      tmp <- spec[, c("pu", "action"), drop = FALSE]

      if (nrow(dplyr::distinct(tmp)) != nrow(tmp)) {
        stop(
          what, " has duplicate (pu, action) rows. Please de-duplicate.",
          call. = FALSE
        )
      }

      out <- spec[spec$feasible, c("pu", "action"), drop = FALSE]
      return(out)
    }

    if (is.list(spec)) {
      if (is.null(names(spec)) || any(names(spec) == "")) {
        stop(
          "If '", what, "' is a list, it must be a named list with names = action ids.",
          call. = FALSE
        )
      }

      if (!all(names(spec) %in% action_ids)) {
        bad <- setdiff(names(spec), action_ids)
        stop(
          what, " list contains unknown actions: ",
          paste(bad, collapse = ", "),
          call. = FALSE
        )
      }

      out <- vector("list", length(spec))
      names(out) <- names(spec)

      for (a in names(spec)) {
        item <- spec[[a]]

        if (is.null(item)) {
          out[[a]] <- NULL
          next
        }

        if (inherits(item, "sf")) {
          .check_spatial_ready(what, pu_sf)

          pu_sf2 <- pu_sf
          pu_sf2$id <- as_int_id_fun(
            pu_sf2$id,
            "x$data$pu_sf$id"
          )

          out[[a]] <- .spatial_pairs(
            pu_sf = pu_sf2,
            zone = item,
            action = a,
            what = what,
            as_int_id_fun = as_int_id_fun,
            compute_area = compute_area
          )

        } else {
          ids <- unique(
            as_int_id_fun(
              item,
              paste0(what, "[['", a, "']]")
            )
          )

          if (!all(ids %in% pu_ids)) {
            bad <- ids[!ids %in% pu_ids]
            stop(
              what, "[[", a, "]] contains PU ids not present in x: ",
              paste(bad, collapse = ", "),
              call. = FALSE
            )
          }

          out[[a]] <- data.frame(
            pu = ids,
            action = a,
            stringsAsFactors = FALSE
          )
        }
      }

      out_df <- dplyr::bind_rows(out)

      if (nrow(out_df) == 0L) {
        return(.empty_pairs(with_area = compute_area))
      }

      out_df$pu <- as_int_id_fun(
        out_df$pu,
        paste0(what, "$pu")
      )
      out_df$action <- as.character(out_df$action)

      if ("action_area" %in% names(out_df)) {
        out_df <- dplyr::group_by(
          out_df,
          .data$pu,
          .data$action
        )
        out_df <- dplyr::summarise(
          out_df,
          action_area = if (all(is.na(.data$action_area))) {
            NA_real_
          } else {
            sum(.data$action_area, na.rm = TRUE)
          },
          .groups = "drop"
        )
        out_df <- as.data.frame(out_df)
      } else {
        out_df <- dplyr::distinct(out_df)
      }

      return(out_df)
    }

    stop(
      "Unsupported type for '", what, "'. Use NULL, data.frame, or a named list.",
      call. = FALSE
    )
  }

  .process_action_area <- function(
    action_area,
    dist_actions,
    pu_ids,
    action_ids,
    as_int_id_fun
  ) {
    if (!inherits(action_area, "data.frame")) {
      stop("`action_area` must be NULL or a data.frame.", call. = FALSE)
    }

    if ("id" %in% names(action_area) && !("action" %in% names(action_area))) {
      names(action_area)[names(action_area) == "id"] <- "action"
    }

    if ("area" %in% names(action_area) && !("action_area" %in% names(action_area))) {
      names(action_area)[names(action_area) == "area"] <- "action_area"
    }

    if (!all(c("pu", "action", "action_area") %in% names(action_area))) {
      stop(
        "`action_area` data.frame must contain columns `pu`, `action`, and `action_area`.",
        call. = FALSE
      )
    }

    action_area$pu <- as_int_id_fun(
      action_area$pu,
      "action_area$pu"
    )
    action_area$action <- as.character(action_area$action)

    if (
      anyNA(action_area$action) ||
      any(!nzchar(action_area$action))
    ) {
      stop(
        "action_area$action must contain non-empty action ids.",
        call. = FALSE
      )
    }

    if (!all(action_area$pu %in% pu_ids)) {
      bad <- unique(action_area$pu[!action_area$pu %in% pu_ids])
      stop(
        "action_area contains unknown pu id(s): ",
        paste(bad, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    if (!all(action_area$action %in% action_ids)) {
      bad <- unique(action_area$action[!action_area$action %in% action_ids])
      stop(
        "action_area contains unknown action id(s): ",
        paste(bad, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    tmp <- action_area[, c("pu", "action"), drop = FALSE]

    if (nrow(dplyr::distinct(tmp)) != nrow(tmp)) {
      stop(
        "action_area has duplicate (pu, action) rows.",
        call. = FALSE
      )
    }

    if (
      !is.numeric(action_area$action_area) ||
      anyNA(action_area$action_area) ||
      any(!is.finite(action_area$action_area))
    ) {
      stop(
        "action_area$action_area must contain only finite, non-missing numeric values.",
        call. = FALSE
      )
    }

    if (any(action_area$action_area < 0)) {
      stop(
        "action_area values must be non-negative.",
        call. = FALSE
      )
    }

    key_da <- paste(
      dist_actions$pu,
      dist_actions$action,
      sep = "||"
    )
    key_aa <- paste(
      action_area$pu,
      action_area$action,
      sep = "||"
    )

    unused <- setdiff(
      key_aa,
      key_da
    )

    if (length(unused) > 0L) {
      warning(
        "`action_area` contains (pu, action) pair(s) that are not feasible in ",
        "`dist_actions`; these rows will be ignored.",
        call. = FALSE,
        immediate. = TRUE
      )
    }

    m <- match(
      key_da,
      key_aa
    )
    hit <- !is.na(m)

    out <- rep(NA_real_, nrow(dist_actions))
    out[hit] <- action_area$action_area[m[hit]]

    out
  }

  # ---- checks: x
  assertthat::assert_that(!is.null(x), msg = "x is NULL")
  assertthat::assert_that(!is.null(x$data), msg = "x does not look like a multiscape Problem object")
  assertthat::assert_that(
    !is.null(x$data$pu),
    !is.null(x$data$features),
    !is.null(x$data$dist_features),
    msg = "x must be created with create_problem()"
  )

  x <- .pa_clone_data(x)

  if (is.null(x$data$pu$internal_id)) {
    x$data$pu$internal_id <- seq_len(nrow(x$data$pu))
  }

  x$data$pu$id <- .as_int_id(
    x$data$pu$id,
    "x$data$pu$id"
  )

  pu_ids <- x$data$pu$id
  pu_index <- stats::setNames(
    x$data$pu$internal_id,
    as.character(x$data$pu$id)
  )

  # ---- actions catalog
  assertthat::assert_that(
    inherits(actions, "data.frame"),
    nrow(actions) > 0
  )

  if ("action" %in% names(actions) && !("id" %in% names(actions))) {
    warning(
      "actions has column 'action'. Renaming it to 'id'.",
      call. = FALSE,
      immediate. = TRUE
    )
    names(actions)[names(actions) == "action"] <- "id"
  }

  assertthat::assert_that(
    assertthat::has_name(actions, "id"),
    assertthat::noNA(actions$id)
  )

  actions$id <- as.character(actions$id)

  if (any(!nzchar(actions$id))) {
    stop(
      "actions$id cannot contain empty strings.",
      call. = FALSE
    )
  }

  if (anyDuplicated(actions$id) != 0L) {
    duplicates <- unique(
      actions$id[duplicated(actions$id)]
    )

    stop(
      "actions$id must be unique. Duplicated id(s): ",
      paste(duplicates, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  if (!("name" %in% names(actions))) {
    actions$name <- as.character(actions$id)
  } else {
    actions$name <- as.character(actions$name)
    if (anyNA(actions$name) || any(!nzchar(actions$name))) {
      stop("actions$name cannot contain NA or empty strings.", call. = FALSE)
    }
  }

  if ("action_set" %in% names(actions)) {
    actions$action_set <- as.character(actions$action_set)
    if (anyNA(actions$action_set) || any(!nzchar(actions$action_set))) {
      stop("actions$action_set cannot contain NA or empty strings.", call. = FALSE)
    }
  }

  actions <- actions[order(actions$id), , drop = FALSE]

  if (!("internal_id" %in% names(actions))) {
    actions$internal_id <- seq_len(nrow(actions))
  } else {
    actions$internal_id <- as.integer(actions$internal_id)
    if (base::anyNA(actions$internal_id)) {
      stop("actions$internal_id contains NA.", call. = FALSE)
    }
    if (anyDuplicated(actions$internal_id) != 0) {
      stop("actions$internal_id must be unique if provided.", call. = FALSE)
    }
  }

  action_ids <- actions$id
  action_index <- stats::setNames(
    actions$internal_id,
    actions$id
  )

  if (is.null(x$data$index) || !is.list(x$data$index)) {
    x$data$index <- list()
  }
  x$data$index$pu <- pu_index
  x$data$index$action <- action_index

  # ---- build feasible pairs
  pu_sf <- x$data$pu_sf

  include_df <- .spec_to_pairs(
    spec = include_pairs,
    what = "include_pairs",
    action_ids = action_ids,
    pu_ids = pu_ids,
    pu_sf = pu_sf,
    as_int_id_fun = .as_int_id,
    compute_area = TRUE
  )

  exclude_df <- .spec_to_pairs(
    spec = exclude_pairs,
    what = "exclude_pairs",
    action_ids = action_ids,
    pu_ids = pu_ids,
    pu_sf = pu_sf,
    as_int_id_fun = .as_int_id,
    compute_area = FALSE
  )

  if (is.null(include_df)) {
    dist_actions <- base::expand.grid(
      pu = pu_ids,
      action = action_ids,
      KEEP.OUT.ATTRS = FALSE,
      stringsAsFactors = FALSE
    )
  } else {
    dist_actions <- include_df
  }

  if (!"action_area" %in% names(dist_actions)) {
    dist_actions$action_area <- NA_real_
  }

  if (!is.null(exclude_df) && nrow(exclude_df) > 0) {
    key_da <- paste(
      dist_actions$pu,
      dist_actions$action,
      sep = "||"
    )
    key_ex <- paste(
      exclude_df$pu,
      exclude_df$action,
      sep = "||"
    )
    keep <- !(key_da %in% key_ex)
    dist_actions <- dist_actions[keep, , drop = FALSE]
  }

  if (nrow(dist_actions) == 0) {
    stop(
      "No feasible (pu, action) pairs were created after applying include_pairs/exclude_pairs.",
      call. = FALSE
    )
  }

  dist_actions$pu <- .as_int_id(
    dist_actions$pu,
    "dist_actions$pu"
  )
  dist_actions$action <- as.character(dist_actions$action)

  # ---- action areas
  if (!is.null(action_area)) {
    user_action_area <- .process_action_area(
      action_area = action_area,
      dist_actions = dist_actions,
      pu_ids = pu_ids,
      action_ids = action_ids,
      as_int_id_fun = .as_int_id
    )

    hit <- !is.na(user_action_area)
    dist_actions$action_area[hit] <- user_action_area[hit]
  }

  missing_action_area <- is.na(dist_actions$action_area)

  if (any(missing_action_area)) {
    pu_area <- tryCatch(
      .pa_get_area_vec(
        x,
        area_col = NULL,
        area_unit = "m2"
      ),
      error = function(e) NULL
    )

    if (!is.null(pu_area)) {
      pu_area <- as.numeric(pu_area)
      names(pu_area) <- as.character(x$data$pu$id)

      fill_values <- pu_area[
        as.character(dist_actions$pu[missing_action_area])
      ]

      dist_actions$action_area[missing_action_area] <- as.numeric(fill_values)
    }
  }

  if (
    any(
      !is.na(dist_actions$action_area) &
      !is.finite(dist_actions$action_area)
    )
  ) {
    stop(
      "action_area contains non-finite values.",
      call. = FALSE
    )
  }

  if (
    any(
      !is.na(dist_actions$action_area) &
      dist_actions$action_area < 0
    )
  ) {
    stop(
      "action_area values must be non-negative.",
      call. = FALSE
    )
  }

  if (
    any(
      !is.na(dist_actions$action_area) &
      dist_actions$action_area < 0
    )
  ) {
    stop(
      "action_area values must be non-negative.",
      call. = FALSE
    )
  }



  # ---- costs
  dist_actions$cost <- 1

  if (is.null(cost)) {

    # Keep the default cost of one for every feasible pair.

  } else if (
    is.numeric(cost) &&
    !is.null(names(cost))
  ) {

    cost_names <- names(cost)

    if (
      anyNA(cost_names) ||
      any(!nzchar(cost_names))
    ) {
      stop(
        "Named `cost` vectors must have non-empty action ids.",
        call. = FALSE
      )
    }

    if (anyDuplicated(cost_names) > 0L) {
      duplicates <- unique(
        cost_names[duplicated(cost_names)]
      )

      stop(
        "Named `cost` vector contains duplicated action id(s): ",
        paste(duplicates, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    unknown_actions <- setdiff(
      cost_names,
      action_ids
    )

    if (length(unknown_actions) > 0L) {
      stop(
        "cost contains unknown action id(s): ",
        paste(unknown_actions, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    missing_actions <- setdiff(
      action_ids,
      cost_names
    )

    if (length(missing_actions) > 0L) {
      stop(
        "Named `cost` vector is missing action id(s): ",
        paste(missing_actions, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    if (
      anyNA(cost) ||
      any(!is.finite(cost))
    ) {
      stop(
        "Named `cost` vector must contain only finite, non-missing values.",
        call. = FALSE
      )
    }

    if (any(cost < 0)) {
      stop(
        "Action costs must be non-negative.",
        call. = FALSE
      )
    }

    dist_actions$cost <- as.numeric(
      cost[dist_actions$action]
    )

  } else if (
    is.numeric(cost) &&
    length(cost) == 1L
  ) {

    if (
      is.na(cost) ||
      !is.finite(cost)
    ) {
      stop(
        "`cost` must be a finite, non-missing number.",
        call. = FALSE
      )
    }

    if (cost < 0) {
      stop(
        "Action costs must be non-negative.",
        call. = FALSE
      )
    }

    dist_actions$cost <- as.numeric(cost)

  } else if (inherits(cost, "data.frame")) {

    if ("id" %in% names(cost) && !("action" %in% names(cost))) {
      names(cost)[names(cost) == "id"] <- "action"
    }

    if (
      all(c("action", "cost") %in% names(cost)) &&
      !("pu" %in% names(cost))
    ) {

      cost$action <- as.character(cost$action)

      if (
        anyNA(cost$action) ||
        any(!nzchar(cost$action))
      ) {
        stop(
          "cost$action must contain non-empty action ids.",
          call. = FALSE
        )
      }

      if (!all(cost$action %in% action_ids)) {
        bad <- unique(
          cost$action[!cost$action %in% action_ids]
        )

        stop(
          "cost contains unknown actions: ",
          paste(bad, collapse = ", "),
          ".",
          call. = FALSE
        )
      }

      if (
        nrow(dplyr::distinct(cost[, "action", drop = FALSE])) !=
        nrow(cost)
      ) {
        stop(
          "cost (action, cost) must have unique action rows.",
          call. = FALSE
        )
      }

      missing_actions <- setdiff(
        action_ids,
        cost$action
      )

      if (length(missing_actions) > 0L) {
        stop(
          "cost data.frame is missing action id(s): ",
          paste(missing_actions, collapse = ", "),
          ".",
          call. = FALSE
        )
      }

      if (
        !is.numeric(cost$cost) ||
        anyNA(cost$cost) ||
        any(!is.finite(cost$cost))
      ) {
        stop(
          "cost$cost must contain only finite, non-missing numeric values.",
          call. = FALSE
        )
      }

      if (any(cost$cost < 0)) {
        stop(
          "Action costs must be non-negative.",
          call. = FALSE
        )
      }

      m <- match(
        dist_actions$action,
        cost$action
      )

      dist_actions$cost <- cost$cost[m]

    } else if (
      all(c("pu", "action", "cost") %in% names(cost))
    ) {

      cost$pu <- .as_int_id(
        cost$pu,
        "cost$pu"
      )
      cost$action <- as.character(cost$action)

      if (
        anyNA(cost$action) ||
        any(!nzchar(cost$action))
      ) {
        stop(
          "cost$action must contain non-empty action ids.",
          call. = FALSE
        )
      }

      if (!all(cost$pu %in% pu_ids)) {
        bad <- unique(
          cost$pu[!cost$pu %in% pu_ids]
        )

        stop(
          "cost contains unknown pu id(s): ",
          paste(bad, collapse = ", "),
          ".",
          call. = FALSE
        )
      }

      if (!all(cost$action %in% action_ids)) {
        bad <- unique(
          cost$action[!cost$action %in% action_ids]
        )

        stop(
          "cost contains unknown action id(s): ",
          paste(bad, collapse = ", "),
          ".",
          call. = FALSE
        )
      }

      tmp <- cost[, c("pu", "action"), drop = FALSE]

      if (
        nrow(dplyr::distinct(tmp)) != nrow(tmp)
      ) {
        stop(
          "cost has duplicate (pu, action) rows.",
          call. = FALSE
        )
      }

      if (
        !is.numeric(cost$cost) ||
        anyNA(cost$cost) ||
        any(!is.finite(cost$cost))
      ) {
        stop(
          "cost$cost must contain only finite, non-missing numeric values.",
          call. = FALSE
        )
      }

      if (any(cost$cost < 0)) {
        stop(
          "Action costs must be non-negative.",
          call. = FALSE
        )
      }

      key_da <- paste(
        dist_actions$pu,
        dist_actions$action,
        sep = "||"
      )
      key_c <- paste(
        cost$pu,
        cost$action,
        sep = "||"
      )

      unknown_pairs <- setdiff(
        key_c,
        key_da
      )

      if (length(unknown_pairs) > 0L) {
        stop(
          "cost contains (pu, action) pair(s) that are not feasible: ",
          paste(unknown_pairs, collapse = ", "),
          ".",
          call. = FALSE
        )
      }

      m <- match(
        key_da,
        key_c
      )
      hit <- !is.na(m)

      # Rows not explicitly supplied retain the default cost of one.
      dist_actions$cost[hit] <- cost$cost[m[hit]]

    } else {
      stop(
        paste0(
          "Unsupported cost data.frame format. Use columns ",
          "(action, cost) or (pu, action, cost)."
        ),
        call. = FALSE
      )
    }

  } else {
    stop(
      "Unsupported type for `cost`.",
      call. = FALSE
    )
  }

  if (!is.numeric(dist_actions$cost)) {
    stop(
      "Internal error: processed action costs are not numeric.",
      call. = FALSE
    )
  }

  if (
    anyNA(dist_actions$cost) ||
    any(!is.finite(dist_actions$cost))
  ) {
    stop(
      paste0(
        "Some feasible (pu, action) pairs have missing or invalid ",
        "costs after processing `cost`."
      ),
      call. = FALSE
    )
  }

  if (any(dist_actions$cost < 0)) {
    stop(
      "Action costs must be non-negative.",
      call. = FALSE
    )
  }

  # ---- initialize status as free
  dist_actions$status <- 0L

  # ---- enforce PU locked_out
  # if ("locked_out" %in% names(x$data$pu)) {
  #   pu_locked_out <- x$data$pu$locked_out
  #   pu_locked_out[is.na(pu_locked_out)] <- FALSE
  #   pu_locked_out <- as.logical(pu_locked_out)
  #
  #   locked_out_pus <- x$data$pu$id[pu_locked_out]
  #
  #   if (length(locked_out_pus) > 0) {
  #     idx_pu_lo <- dist_actions$pu %in% locked_out_pus
  #     dist_actions$status[idx_pu_lo] <- 3L
  #   }
  # }

  # ---- add internal ids
  dist_actions$internal_pu <- unname(
    pu_index[as.character(dist_actions$pu)]
  )
  dist_actions$internal_action <- unname(
    action_index[as.character(dist_actions$action)]
  )

  dist_actions <- dist_actions[
    order(dist_actions$internal_pu, dist_actions$internal_action),
    ,
    drop = FALSE
  ]

  if (anyNA(dist_actions$internal_pu)) {
    stop("Internal error: could not map pu -> internal_pu.", call. = FALSE)
  }

  if (anyNA(dist_actions$internal_action)) {
    stop("Internal error: could not map action -> internal_action.", call. = FALSE)
  }

  # Keep a stable column order.
  dist_actions <- dist_actions[
    ,
    c(
      "pu",
      "action",
      "cost",
      "status",
      "internal_pu",
      "internal_action",
      "action_area"
    ),
    drop = FALSE
  ]

  x$data$actions <- actions
  x$data$dist_actions <- dist_actions

  x
}

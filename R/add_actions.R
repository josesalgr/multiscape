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
#' When spatial \code{include_pairs} are supplied as \code{sf} layers, the
#' function also stores the planning unit--action intersection geometries in
#' \code{x$data$dist_actions_sf}. This auxiliary table is not used directly by
#' the base action model, but can be used by downstream constraints that require
#' exact spatial overlaps between actions and other spatial entities, such as
#' groups.
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
#' spatial intersections against the stored planning-unit geometry. If
#' \code{include_pairs} or \code{exclude_pairs} contains \code{sf} objects, the
#' problem must contain planning-unit geometry in \code{x$data$pu_sf}; otherwise
#' an error is raised.
#'
#' Spatial exclusions are applied after inclusions. If a planning unit--action
#' pair is included and excluded, the exclusion takes precedence and the pair is
#' removed. Spatial exclusions remove complete \code{(pu, action)} pairs; they
#' do not partially subtract area from included geometries.
#'
#' \strong{Action areas and action intersection geometries.}
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
#' When \code{include_pairs} contains \code{sf} objects, the corresponding
#' planning unit--action intersection geometries are stored in
#' \code{x$data$dist_actions_sf}. This object contains columns \code{pu},
#' \code{action}, \code{internal_pu}, \code{internal_action},
#' \code{action_area}, and geometry. It is intended for downstream spatial
#' constraints that require exact overlaps between selected actions and other
#' spatial layers.
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
#'#'
#' @param progress Logical. If \code{TRUE}, show progress messages for large
#'   spatial action intersections when the \code{cli} package is available.
#'
#' @param chunk_size Positive integer. Number of candidate planning units to
#'   process per chunk when spatial action zones require partial intersections.
#'   Smaller values reduce peak memory use; larger values may be faster when
#'   enough memory is available.
#'

#' @return An updated \code{Problem} object with:
#' \describe{
#'   \item{\code{actions}}{The action catalogue, including a unique integer
#'   \code{internal_id} for each action.}
#'   \item{\code{dist_actions}}{The feasible planning unit--action table with
#'   columns \code{pu}, \code{action}, \code{cost}, \code{action_area},
#'   \code{status}, \code{internal_pu}, and \code{internal_action}.}
#'   \item{\code{dist_actions_sf}}{When spatial \code{include_pairs} are used,
#'   an \code{sf} object containing the exact planning unit--action
#'   intersection geometries.}
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
    action_area = NULL,
    progress = TRUE,
    chunk_size = 5000
) {

  .as_int_id <- function(v, what) {
    if (is.factor(v)) v <- as.character(v)

    if (is.character(v)) {
      if (any(grepl("[^0-9\\-]", v))) {
        stop(
          what,
          " must be numeric/integer ids (got non-numeric strings).",
          call. = FALSE
        )
      }

      v <- as.integer(v)
    } else {
      v <- as.integer(v)
    }

    if (anyNA(v)) {
      stop(
        what,
        " contains NA after coercion to integer.",
        call. = FALSE
      )
    }

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

  .empty_pairs <- function(with_area = FALSE,
                           with_geometry = FALSE,
                           crs = NA) {
    if (isTRUE(with_geometry)) {
      if (!requireNamespace("sf", quietly = TRUE)) {
        stop(
          "Package `sf` is required to create empty spatial pairs.",
          call. = FALSE
        )
      }

      return(sf::st_sf(
        pu = integer(0),
        action = character(0),
        action_area = numeric(0),
        geometry = sf::st_sfc(crs = crs)
      ))
    }

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
      stop(
        what,
        " provided as sf layers requires the 'sf' package.",
        call. = FALSE
      )
    }

    if (is.null(pu_sf) || !inherits(pu_sf, "sf")) {
      stop(
        "To use '", what, "' as sf layers, the problem object must contain ",
        "x$data$pu_sf (sf planning unit geometry).",
        call. = FALSE
      )
    }

    if (!("id" %in% names(pu_sf))) {
      stop(
        "x$data$pu_sf is missing an 'id' column.",
        call. = FALSE
      )
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
      zone <- sf::st_transform(
        zone,
        sf::st_crs(pu_sf)
      )
    }

    zone
  }

  .spatial_pairs <- function(x,
                             action_id,
                             zone_sf,
                             compute_area = TRUE,
                             keep_geometry = FALSE,
                             progress = TRUE,
                             chunk_size = 5000) {
    pu_sf <- x$data$pu_sf

    pu_geom <- pu_sf[, "id", drop = FALSE]

    if (sf::st_crs(pu_geom) != sf::st_crs(zone_sf)) {
      zone_sf <- sf::st_transform(zone_sf, sf::st_crs(pu_geom))
    }

    if (nrow(zone_sf) == 1L) {
      zone_union <- sf::st_sf(
        action = action_id,
        geometry = sf::st_geometry(zone_sf)
      )
    } else {
      zone_union <- sf::st_sf(
        action = action_id,
        geometry = sf::st_sfc(
          sf::st_union(sf::st_geometry(zone_sf)),
          crs = sf::st_crs(pu_geom)
        )
      )
    }

    # 1. Candidatas: intersectan o tocan la zona
    hits_intersects <- sf::st_intersects(
      pu_geom,
      zone_union,
      sparse = TRUE
    )

    idx_intersects <- which(lengths(hits_intersects) > 0L)

    if (length(idx_intersects) == 0L) {
      if (isTRUE(keep_geometry)) {
        return(
          sf::st_sf(
            pu = integer(),
            action = character(),
            action_area = numeric(),
            geometry = sf::st_sfc(crs = sf::st_crs(pu_geom))
          )
        )
      }

      return(
        data.frame(
          pu = integer(),
          action = character(),
          action_area = numeric()
        )
      )
    }

    pu_candidates <- pu_geom[idx_intersects, , drop = FALSE]

    # 2. Full cover: PUs completamente dentro/cubiertas por la zona
    # hits_covered <- sf::st_covered_by(
    #   pu_candidates,
    #   zone_union,
    #   sparse = TRUE
    # )
    #
    # idx_full_local <- which(lengths(hits_covered) > 0L)
    # idx_full <- idx_intersects[idx_full_local]
    #
    # idx_partial <- setdiff(idx_intersects, idx_full)

    idx_full <- integer(0)
    idx_partial <- idx_intersects

    # 3. PUs completamente cubiertas: no necesitan st_intersection()
    full_out <- NULL

    if (length(idx_full) > 0L) {
      full_out <- pu_geom[idx_full, , drop = FALSE]

      full_out$pu <- as.integer(full_out$id)
      full_out$action <- as.character(action_id)
      full_out$action_area <- as.numeric(sf::st_area(full_out))

      if (isTRUE(keep_geometry)) {
        full_out <- full_out |>
          dplyr::select(
            pu,
            action,
            action_area,
            geometry
          )
      } else {
        full_out <- full_out |>
          sf::st_drop_geometry() |>
          dplyr::select(
            pu,
            action,
            action_area
          )
      }
    }

    # 4. PUs parciales: solo estas requieren intersección real
    partial_out <- NULL

    if (length(idx_partial) > 0L) {
      idx_chunks <- split(
        idx_partial,
        ceiling(seq_along(idx_partial) / chunk_size)
      )

      use_cli <- isTRUE(progress) && requireNamespace("cli", quietly = TRUE)

      if (use_cli) {
        cli::cli_progress_bar(
          name = paste0("Intersecting partial PUs for action `", action_id, "`"),
          total = length(idx_chunks),
          type = "iterator",
          clear = FALSE
        )
      }

      partial_list <- vector("list", length(idx_chunks))

      for (k in seq_along(idx_chunks)) {
        pu_sub <- pu_geom[idx_chunks[[k]], , drop = FALSE]

        inter_k <- suppressWarnings(
          sf::st_intersection(
            pu_sub,
            zone_union
          )
        )

        if (nrow(inter_k) > 0L) {
          inter_k$pu <- as.integer(inter_k$id)
          inter_k$action <- as.character(action_id)
          inter_k$action_area <- as.numeric(sf::st_area(inter_k))

          inter_k <- inter_k |>
            dplyr::filter(
              !is.na(.data$action_area),
              is.finite(.data$action_area),
              .data$action_area > 0
            )

          if (nrow(inter_k) > 0L) {
            if (isTRUE(keep_geometry)) {
              partial_list[[k]] <- inter_k |>
                dplyr::select(
                  pu,
                  action,
                  action_area,
                  geometry
                )
            } else {
              partial_list[[k]] <- inter_k |>
                sf::st_drop_geometry() |>
                dplyr::select(
                  pu,
                  action,
                  action_area
                )
            }
          }
        }

        if (use_cli) {
          cli::cli_progress_update()
        }
      }

      if (use_cli) {
        cli::cli_progress_done()
      }

      partial_list <- partial_list[
        !vapply(partial_list, is.null, logical(1))
      ]

      if (length(partial_list) > 0L) {
        if (isTRUE(keep_geometry)) {
          partial_out <- do.call(rbind, partial_list)
        } else {
          partial_out <- dplyr::bind_rows(partial_list)
        }
      }
    }

    # 5. Combinar full + partial
    out <- list(full_out, partial_out)
    out <- out[!vapply(out, is.null, logical(1))]

    if (length(out) == 0L) {
      if (isTRUE(keep_geometry)) {
        return(
          sf::st_sf(
            pu = integer(),
            action = character(),
            action_area = numeric(),
            geometry = sf::st_sfc(crs = sf::st_crs(pu_geom))
          )
        )
      }

      return(
        data.frame(
          pu = integer(),
          action = character(),
          action_area = numeric()
        )
      )
    }

    if (isTRUE(keep_geometry)) {
      if (isTRUE(progress) && requireNamespace("cli", quietly = TRUE)) {
        cli::cli_inform(paste0(
          "Action `", action_id, "`: binding final spatial outputs..."
        ))
      }

      ans <- do.call(rbind, out)

      ans$pu <- as.integer(ans$pu)
      ans$action <- as.character(ans$action)
      ans$action_area <- as.numeric(ans$action_area)

      ans <- ans |>
        dplyr::filter(
          !is.na(.data$action_area),
          is.finite(.data$action_area),
          .data$action_area > 0
        )

      key <- paste(ans$pu, ans$action, sep = "||")

      if (anyDuplicated(key) > 0L) {
        if (isTRUE(progress) && requireNamespace("cli", quietly = TRUE)) {
          cli::cli_inform(paste0(
            "Action `", action_id, "`: aggregating duplicated geometries..."
          ))
        }

        ans <- ans |>
          dplyr::group_by(
            .data$pu,
            .data$action
          ) |>
          dplyr::summarise(
            action_area = sum(.data$action_area, na.rm = TRUE),
            geometry = sf::st_union(geometry),
            .groups = "drop"
          ) |>
          sf::st_as_sf()
      } else {
        ans <- ans |>
          dplyr::select(
            pu,
            action,
            action_area,
            geometry
          ) |>
          sf::st_as_sf()
      }

    } else {
      if (isTRUE(progress) && requireNamespace("cli", quietly = TRUE)) {
        cli::cli_inform(paste0(
          "Action `", action_id, "`: binding final tabular outputs..."
        ))
      }

      ans <- dplyr::bind_rows(out)

      ans$pu <- as.integer(ans$pu)
      ans$action <- as.character(ans$action)
      ans$action_area <- as.numeric(ans$action_area)

      ans <- ans |>
        dplyr::filter(
          !is.na(.data$action_area),
          is.finite(.data$action_area),
          .data$action_area > 0
        )

      key <- paste(ans$pu, ans$action, sep = "||")

      if (anyDuplicated(key) > 0L) {
        ans <- ans |>
          dplyr::group_by(
            .data$pu,
            .data$action
          ) |>
          dplyr::summarise(
            action_area = sum(.data$action_area, na.rm = TRUE),
            .groups = "drop"
          ) |>
          as.data.frame()
      } else {
        ans <- as.data.frame(ans)
      }
    }

    ans$pu <- as.integer(ans$pu)
    ans$action <- as.character(ans$action)
    ans$action_area <- as.numeric(ans$action_area)

    if (isTRUE(progress) && requireNamespace("cli", quietly = TRUE)) {
      cli::cli_inform(paste0(
        "Action `", action_id, "`: spatial pairs finished with ",
        nrow(ans), " rows."
      ))
    }

    ans
  }

  .spec_to_pairs <- function(
    spec,
    what,
    action_ids,
    pu_ids,
    pu_sf,
    as_int_id_fun,
    compute_area = FALSE,
    keep_geometry = FALSE,
    spatial_mode = c("all", "spatial", "nonspatial"),
    progress = TRUE,
    chunk_size = 5000
  ) {
    spatial_mode <- match.arg(spatial_mode)

    if (is.null(spec)) {
      return(NULL)
    }

    if (inherits(spec, "data.frame")) {
      if (identical(spatial_mode, "spatial")) {
        return(NULL)
      }

      if (isTRUE(keep_geometry)) {
        return(NULL)
      }

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

      spec$pu <- as_int_id_fun(
        spec$pu,
        paste0(what, "$pu")
      )

      spec$action <- as.character(spec$action)
      spec <- .normalize_feasible_col(spec, what)

      if (!all(spec$pu %in% pu_ids)) {
        bad <- unique(spec$pu[!spec$pu %in% pu_ids])

        stop(
          what,
          " contains PU ids not present in x: ",
          paste(bad, collapse = ", "),
          call. = FALSE
        )
      }

      if (!all(spec$action %in% action_ids)) {
        bad <- unique(spec$action[!spec$action %in% action_ids])

        stop(
          what,
          " contains action ids not present in actions: ",
          paste(bad, collapse = ", "),
          call. = FALSE
        )
      }

      tmp <- spec[, c("pu", "action"), drop = FALSE]

      if (nrow(dplyr::distinct(tmp)) != nrow(tmp)) {
        stop(
          what,
          " has duplicate (pu, action) rows. Please de-duplicate.",
          call. = FALSE
        )
      }

      out <- spec[spec$feasible, c("pu", "action"), drop = FALSE]

      return(out)
    }

    if (is.list(spec)) {
      if (is.null(names(spec)) || any(names(spec) == "")) {
        stop(
          "If '",
          what,
          "' is a list, it must be a named list with names = action ids.",
          call. = FALSE
        )
      }

      if (!all(names(spec) %in% action_ids)) {
        bad <- setdiff(names(spec), action_ids)

        stop(
          what,
          " list contains unknown actions: ",
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

        item_is_sf <- inherits(item, "sf")

        if (identical(spatial_mode, "spatial") && !item_is_sf) {
          out[[a]] <- NULL
          next
        }

        if (identical(spatial_mode, "nonspatial") && item_is_sf) {
          out[[a]] <- NULL
          next
        }

        if (item_is_sf) {
          .check_spatial_ready(
            what = what,
            pu_sf = pu_sf
          )

          if (isTRUE(keep_geometry) || isTRUE(compute_area)) {
            out[[a]] <- .spatial_pairs(
              x = x,
              action_id = a,
              zone_sf = item,
              compute_area = compute_area,
              keep_geometry = keep_geometry,
              progress = progress,
              chunk_size = chunk_size
            )
          } else {
            spatial_tmp <- .spatial_pairs(
              x = x,
              action_id = a,
              zone_sf = item,
              compute_area = TRUE,
              keep_geometry = FALSE,
              progress = progress,
              chunk_size = chunk_size
            )

            out[[a]] <- spatial_tmp[, c("pu", "action"), drop = FALSE]
          }

        } else {
          if (isTRUE(keep_geometry)) {
            out[[a]] <- NULL
            next
          }

          ids <- unique(
            as_int_id_fun(
              item,
              paste0(what, "[['", a, "']]")
            )
          )

          if (!all(ids %in% pu_ids)) {
            bad <- ids[!ids %in% pu_ids]

            stop(
              what,
              "[[",
              a,
              "]] contains PU ids not present in x: ",
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

      out <- out[!vapply(out, is.null, logical(1))]

      if (length(out) == 0L) {
        if (isTRUE(keep_geometry)) {
          return(.empty_pairs(
            with_area = TRUE,
            with_geometry = TRUE,
            crs = if (!is.null(pu_sf) && inherits(pu_sf, "sf")) {
              sf::st_crs(pu_sf)
            } else {
              NA
            }
          ))
        }

        return(.empty_pairs(with_area = compute_area))
      }

      if (isTRUE(keep_geometry)) {
        out_df <- do.call(rbind, out)

        if (!inherits(out_df, "sf")) {
          return(.empty_pairs(
            with_area = TRUE,
            with_geometry = TRUE,
            crs = if (!is.null(pu_sf) && inherits(pu_sf, "sf")) {
              sf::st_crs(pu_sf)
            } else {
              NA
            }
          ))
        }

        out_df$pu <- as_int_id_fun(
          out_df$pu,
          paste0(what, "$pu")
        )

        out_df$action <- as.character(out_df$action)
        out_df$action_area <- as.numeric(out_df$action_area)

        key <- paste(out_df$pu, out_df$action, sep = "||")

        if (anyDuplicated(key) > 0L) {
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
            geometry = sf::st_union(geometry),
            .groups = "drop"
          )

          out_df <- sf::st_as_sf(out_df)

        } else {
          out_df <- out_df |>
            dplyr::select(
              pu,
              action,
              action_area,
              geometry
            ) |>
            sf::st_as_sf()
        }

        return(out_df)
      }

      out_df <- dplyr::bind_rows(out)

      if (is.null(out_df) || nrow(out_df) == 0L) {
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
      "Unsupported type for '",
      what,
      "'. Use NULL, data.frame, or a named list.",
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
      stop(
        "`action_area` must be NULL or a data.frame.",
        call. = FALSE
      )
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

    if (anyNA(action_area$action) ||
        any(!nzchar(action_area$action))) {
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

    if (!is.numeric(action_area$action_area) ||
        anyNA(action_area$action_area) ||
        any(!is.finite(action_area$action_area))) {
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
  assertthat::assert_that(
    !is.null(x),
    msg = "x is NULL"
  )

  assertthat::assert_that(
    !is.null(x$data),
    msg = "x does not look like a multiscape Problem object"
  )

  assertthat::assert_that(
    !is.null(x$data$pu),
    !is.null(x$data$features),
    !is.null(x$data$dist_features),
    msg = "x must be created with create_problem()"
  )

  x <- .pa_clone_data(x)

  if (!is.logical(progress) ||
      length(progress) != 1L ||
      is.na(progress)) {
    stop("`progress` must be TRUE or FALSE.", call. = FALSE)
  }

  if (!is.numeric(chunk_size) ||
      length(chunk_size) != 1L ||
      is.na(chunk_size) ||
      !is.finite(chunk_size) ||
      chunk_size < 1) {
    stop("`chunk_size` must be a positive integer.", call. = FALSE)
  }

  chunk_size <- as.integer(chunk_size)

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
      stop(
        "actions$name cannot contain NA or empty strings.",
        call. = FALSE
      )
    }
  }

  if ("action_set" %in% names(actions)) {
    actions$action_set <- as.character(actions$action_set)

    if (anyNA(actions$action_set) || any(!nzchar(actions$action_set))) {
      stop(
        "actions$action_set cannot contain NA or empty strings.",
        call. = FALSE
      )
    }
  }

  actions <- actions[
    order(actions$id),
    ,
    drop = FALSE
  ]

  if (!("internal_id" %in% names(actions))) {
    actions$internal_id <- seq_len(nrow(actions))
  } else {
    actions$internal_id <- as.integer(actions$internal_id)

    if (base::anyNA(actions$internal_id)) {
      stop(
        "actions$internal_id contains NA.",
        call. = FALSE
      )
    }

    if (anyDuplicated(actions$internal_id) != 0) {
      stop(
        "actions$internal_id must be unique if provided.",
        call. = FALSE
      )
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

  .spec_has_sf <- function(spec) {
    is.list(spec) && any(vapply(spec, inherits, logical(1), what = "sf"))
  }

  include_df <- NULL
  include_sf <- NULL

  if (is.null(include_pairs)) {
    include_df <- NULL
    include_sf <- NULL

  } else if (.spec_has_sf(include_pairs)) {
    # Important: when include_pairs contains sf layers, compute the spatial
    # intersections once with keep_geometry = TRUE and derive the tabular
    # feasible-pair table from that sf result. This avoids doing the same
    # expensive st_intersection() twice.
    include_sf <- .spec_to_pairs(
      spec = include_pairs,
      what = "include_pairs",
      action_ids = action_ids,
      pu_ids = pu_ids,
      pu_sf = pu_sf,
      as_int_id_fun = .as_int_id,
      compute_area = TRUE,
      keep_geometry = TRUE,
      spatial_mode = "spatial",
      progress = progress,
      chunk_size = chunk_size
    )

    include_spatial_df <- if (!is.null(include_sf) &&
                              inherits(include_sf, "sf") &&
                              nrow(include_sf) > 0L) {
      sf::st_drop_geometry(include_sf)
    } else {
      .empty_pairs(with_area = TRUE)
    }

    include_nonspatial_df <- .spec_to_pairs(
      spec = include_pairs,
      what = "include_pairs",
      action_ids = action_ids,
      pu_ids = pu_ids,
      pu_sf = pu_sf,
      as_int_id_fun = .as_int_id,
      compute_area = TRUE,
      keep_geometry = FALSE,
      spatial_mode = "nonspatial",
      progress = progress,
      chunk_size = chunk_size
    )

    include_df <- dplyr::bind_rows(
      include_spatial_df,
      include_nonspatial_df
    )

    if (nrow(include_df) == 0L) {
      include_df <- .empty_pairs(with_area = TRUE)
    }

  } else {
    include_df <- .spec_to_pairs(
      spec = include_pairs,
      what = "include_pairs",
      action_ids = action_ids,
      pu_ids = pu_ids,
      pu_sf = pu_sf,
      as_int_id_fun = .as_int_id,
      compute_area = TRUE,
      keep_geometry = FALSE,
      spatial_mode = "all",
      progress = progress,
      chunk_size = chunk_size
    )

    include_sf <- NULL
  }

  exclude_df <- .spec_to_pairs(
    spec = exclude_pairs,
    what = "exclude_pairs",
    action_ids = action_ids,
    pu_ids = pu_ids,
    pu_sf = pu_sf,
    as_int_id_fun = .as_int_id,
    compute_area = FALSE,
    keep_geometry = FALSE,
    spatial_mode = "all",
    progress = progress,
    chunk_size = chunk_size
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

    dist_actions <- dist_actions[
      keep,
      ,
      drop = FALSE
    ]
  }

  dist_actions_sf <- NULL

  if (!is.null(include_sf) &&
      inherits(include_sf, "sf") &&
      nrow(include_sf) > 0L) {

    if (!is.null(exclude_df) && nrow(exclude_df) > 0L) {
      key_sf <- paste(
        include_sf$pu,
        include_sf$action,
        sep = "||"
      )

      key_ex <- paste(
        exclude_df$pu,
        exclude_df$action,
        sep = "||"
      )

      include_sf <- include_sf[
        !(key_sf %in% key_ex),
        ,
        drop = FALSE
      ]
    }

    if (nrow(include_sf) > 0L) {
      key_da_final <- paste(
        dist_actions$pu,
        dist_actions$action,
        sep = "||"
      )

      key_sf <- paste(
        include_sf$pu,
        include_sf$action,
        sep = "||"
      )

      include_sf <- include_sf[
        key_sf %in% key_da_final,
        ,
        drop = FALSE
      ]
    }

    if (nrow(include_sf) > 0L) {
      dist_actions_sf <- include_sf
    }
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

  if (any(!is.na(dist_actions$action_area) &
          !is.finite(dist_actions$action_area))) {
    stop(
      "action_area contains non-finite values.",
      call. = FALSE
    )
  }

  if (any(!is.na(dist_actions$action_area) &
          dist_actions$action_area < 0)) {
    stop(
      "action_area values must be non-negative.",
      call. = FALSE
    )
  }

  # ---- costs
  dist_actions$cost <- 1

  if (is.null(cost)) {

    # Keep the default cost of one for every feasible pair.

  } else if (is.numeric(cost) &&
             !is.null(names(cost))) {

    cost_names <- names(cost)

    if (anyNA(cost_names) ||
        any(!nzchar(cost_names))) {
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

    if (anyNA(cost) ||
        any(!is.finite(cost))) {
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

  } else if (is.numeric(cost) &&
             length(cost) == 1L) {

    if (is.na(cost) ||
        !is.finite(cost)) {
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

    if (all(c("action", "cost") %in% names(cost)) &&
        !("pu" %in% names(cost))) {

      cost$action <- as.character(cost$action)

      if (anyNA(cost$action) ||
          any(!nzchar(cost$action))) {
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

      if (nrow(dplyr::distinct(cost[, "action", drop = FALSE])) !=
          nrow(cost)) {
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

      if (!is.numeric(cost$cost) ||
          anyNA(cost$cost) ||
          any(!is.finite(cost$cost))) {
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

    } else if (all(c("pu", "action", "cost") %in% names(cost))) {

      cost$pu <- .as_int_id(
        cost$pu,
        "cost$pu"
      )

      cost$action <- as.character(cost$action)

      if (anyNA(cost$action) ||
          any(!nzchar(cost$action))) {
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

      if (nrow(dplyr::distinct(tmp)) != nrow(tmp)) {
        stop(
          "cost has duplicate (pu, action) rows.",
          call. = FALSE
        )
      }

      if (!is.numeric(cost$cost) ||
          anyNA(cost$cost) ||
          any(!is.finite(cost$cost))) {
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
        warning(
          "`cost` contains ",
          length(unknown_pairs),
          " (pu, action) pair(s) that are not feasible in `dist_actions`; ",
          "these rows will be ignored.",
          call. = FALSE,
          immediate. = TRUE
        )

        keep_cost <- key_c %in% key_da

        cost <- cost[
          keep_cost,
          ,
          drop = FALSE
        ]

        key_c <- key_c[keep_cost]

        if (nrow(cost) == 0L) {
          warning(
            "After removing non-feasible (pu, action) rows, no pair-specific ",
            "`cost` rows remain. Feasible pairs will retain their previous/default ",
            "cost values.",
            call. = FALSE,
            immediate. = TRUE
          )
        }
      }

      if (nrow(cost) > 0L) {
        m <- match(
          key_da,
          key_c
        )

        hit <- !is.na(m)

        # Rows not explicitly supplied retain the current/default cost.
        dist_actions$cost[hit] <- cost$cost[m[hit]]
      }

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

  if (anyNA(dist_actions$cost) ||
      any(!is.finite(dist_actions$cost))) {
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
    order(
      dist_actions$internal_pu,
      dist_actions$internal_action
    ),
    ,
    drop = FALSE
  ]

  if (anyNA(dist_actions$internal_pu)) {
    stop(
      "Internal error: could not map pu -> internal_pu.",
      call. = FALSE
    )
  }

  if (anyNA(dist_actions$internal_action)) {
    stop(
      "Internal error: could not map action -> internal_action.",
      call. = FALSE
    )
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

  # ---- finalize spatial action intersections, when available
  if (!is.null(dist_actions_sf) &&
      inherits(dist_actions_sf, "sf") &&
      nrow(dist_actions_sf) > 0L) {

    dist_actions_sf$pu <- .as_int_id(
      dist_actions_sf$pu,
      "dist_actions_sf$pu"
    )

    dist_actions_sf$action <- as.character(
      dist_actions_sf$action
    )

    key_da <- paste(
      dist_actions$pu,
      dist_actions$action,
      sep = "||"
    )

    key_sf <- paste(
      dist_actions_sf$pu,
      dist_actions_sf$action,
      sep = "||"
    )

    dist_actions_sf <- dist_actions_sf[
      key_sf %in% key_da,
      ,
      drop = FALSE
    ]

    if (nrow(dist_actions_sf) > 0L) {
      dist_actions_sf$internal_pu <- unname(
        pu_index[as.character(dist_actions_sf$pu)]
      )

      dist_actions_sf$internal_action <- unname(
        action_index[as.character(dist_actions_sf$action)]
      )

      if (anyNA(dist_actions_sf$internal_pu)) {
        stop(
          "Internal error: could not map dist_actions_sf$pu -> internal_pu.",
          call. = FALSE
        )
      }

      if (anyNA(dist_actions_sf$internal_action)) {
        stop(
          "Internal error: could not map dist_actions_sf$action -> internal_action.",
          call. = FALSE
        )
      }

      key_sf <- paste(
        dist_actions_sf$pu,
        dist_actions_sf$action,
        sep = "||"
      )

      dist_actions_sf <- dist_actions_sf[
        order(match(key_sf, key_da)),
        ,
        drop = FALSE
      ]

      dist_actions_sf <- dist_actions_sf[
        ,
        c(
          "pu",
          "action",
          "internal_pu",
          "internal_action",
          "action_area"
        ),
        drop = FALSE
      ]

      dist_actions_sf <- sf::st_as_sf(dist_actions_sf)
    } else {
      dist_actions_sf <- NULL
    }
  } else {
    dist_actions_sf <- NULL
  }

  x$data$actions <- actions
  x$data$dist_actions <- dist_actions
  x$data$dist_actions_sf <- dist_actions_sf

  if (!is.null(x$data$model_ptr)) {
    x$data$meta <- x$data$meta %||% list()
    x$data$meta$model_dirty <- TRUE
  }

  x
}

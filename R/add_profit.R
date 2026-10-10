#' @include internal.R
#'
#' @title Add profit to a planning problem
#'
#' @description
#' Assign economic returns to feasible planning-unit--action pairs. Returns
#' may be positive, zero, or negative and are stored separately from
#' implementation costs and ecological effects.
#'
#' @details
#' \strong{Economic returns and implementation costs}
#'
#' An economic return \eqn{\pi_{ia}} is the monetary contribution associated
#' with selecting action \eqn{a} in planning unit \eqn{i}. Positive values
#' represent gains or revenues; negative values represent penalties or
#' economic losses. A zero value contributes no profit.
#'
#' Profit is registered independently of planning-unit and action costs.
#' \code{add_objective_max_profit()} maximises the sum of registered returns,
#' whereas \code{add_objective_max_net_profit()} can subtract implementation
#' costs. If your profit inputs already account for these costs, avoid
#' subtracting them again when configuring the objective. Economic returns
#' should not be confused with the signed ecological changes registered
#' using \code{add_effects()}.
#'
#' \strong{Supported input formats}
#'
#' The \code{profit} argument accepts:
#' \itemize{
#'   \item \code{NULL}: zero profit for all feasible pairs;
#'   \item one numeric value: the same profit for every feasible pair;
#'   \item a named numeric vector: one profit value per named action;
#'   \item \code{data.frame(action, profit)}: one profit value per action;
#'   \item \code{data.frame(pu, action, profit)}: values specific to
#'     individual planning-unit--action pairs.
#' }
#'
#' An action-level value applies to all feasible planning units for that
#' action. A pair-specific table permits spatially varying returns. Feasible
#' pairs not specified in the input receive profit zero.
#'
#' \strong{Storage and use in planning}
#'
#' Only non-zero values are stored in \code{dist_profit}. Zero-profit pairs
#' are omitted from the table but remain feasible. The stored columns are
#' \code{pu}, \code{action}, \code{profit}, \code{internal_pu}, and
#' \code{internal_action}. Calling \code{add_profit()} neither selects actions
#' nor modifies feasible actions or ecological effects; the values are used
#' later by objectives, constraints, and solution summaries.
#'
#' Profit can be defined only once per problem, including when supplying
#' \code{NULL}. To compare economic scenarios, start from the same problem
#' before profit was added.
#'
#' @param x A \code{Problem} object created with \code{\link{create_problem}}. It
#'   must already contain feasible actions and an action catalogue; run
#'   \code{\link{add_actions}} first.
#'
#' @param profit Profit specification. One of:
#' \itemize{
#'   \item \code{NULL}: profit is set to 0 for all feasible
#'   \code{(pu, action)} pairs,
#'   \item a numeric scalar: recycled to all feasible pairs,
#'   \item a named numeric vector: names are action ids and values define
#'   action-level profit,
#'   \item a \code{data.frame(action, profit)} defining action-level profit,
#'   \item a \code{data.frame(pu, action, profit)} defining pair-specific
#'   profit.
#' }
#'
#' Profit can be defined only once per problem, including explicit zero profit.
#' A second call raises an error. To compare profit scenarios, build separate
#' problems from the object before profit was added.
#'
#' @return An updated \code{Problem} object with a stored profit table created.
#'   The stored table contains columns \code{pu}, \code{action},
#'   \code{profit}, \code{internal_pu}, and \code{internal_action}, and
#'   includes only rows with non-zero profit.
#'
#' @examples
#' # EXAMPLE 1: Create a planning problem with feasible actions
#'
#' # The bundled 64-unit landscape has protection and restoration
#' # alternatives. Action implementation costs are registered separately
#' # from the economic returns introduced below.
#'
#' sim <- load_sim_multiaction()
#'
#' p <- create_problem(
#'   pu = sim$planning_units,
#'   features = sim$features,
#'   dist_features = sim$dist_features,
#'   cost = "cost"
#' ) |>
#'   add_actions(
#'     actions = sim$actions,
#'     cost = sim$action_costs
#'   )
#'
#' # EXAMPLE 2: A constant economic return
#'
#' # Suppose implementing any feasible action generates 10 monetary units,
#' # regardless of the action or its location. A scalar is applied to all
#' # feasible planning-unit--action pairs.
#'
#' p_constant <- add_profit(p, profit = 10)
#' head(p_constant$data$dist_profit[, c("pu", "action", "profit")])
#'
#' # EXAMPLE 3: Action-specific returns
#'
#' # Protection generates +50 monetary units, whereas restoration incurs
#' # an economic penalty of -5 units. A named vector assigns a value to
#' # every feasible planning unit where that action is available.
#'
#' returns <- c(protect = 50, restore = -5)
#' p_action <- add_profit(p, profit = returns)
#' head(p_action$data$dist_profit[, c("pu", "action", "profit")])
#'
#' # The same action-level values can be supplied as a data frame.
#' # These alternatives start from the same base problem because profit
#' # can be defined only once per problem.
#'
#' p_action_table <- add_profit(p, data.frame(
#'   action = c("protect", "restore"),
#'   profit = c(50, -5)
#' ))
#' head(p_action_table$data$dist_profit[, c("pu", "action", "profit")])
#'
#' # EXAMPLE 4: Location-specific economic returns
#'
#' # The same action can have different returns across planning units.
#' # Protection provides +100 in unit 1 and +80 in unit 2; restoration
#' # provides +30 in unit 3. Unlisted feasible pairs receive zero profit.
#'
#' local_returns <- data.frame(
#'   pu = c(1, 2, 3),
#'   action = c("protect", "protect", "restore"),
#'   profit = c(100, 80, 30)
#' )
#' p_local <- add_profit(p, profit = local_returns)
#'
#' # Only the three non-zero contributions are stored. This does not
#' # make any of the other, zero-profit action pairs infeasible.
#' p_local$data$dist_profit[, c("pu", "action", "profit")]
#'
#' # EXAMPLE 5: Explicitly specify no economic return
#'
#' # NULL assigns zero to every feasible pair. The resulting sparse
#' # profit table is empty, even though the actions remain available.
#'
#' p_zero <- add_profit(p, profit = NULL)
#' nrow(p_zero$data$dist_profit)
#'
#' # EXAMPLE 6: Map spatially varying potential returns
#'
#' # The simulated planning units include geometry and an x-coordinate.
#' # Give restoration a hypothetical return that increases from west to
#' # east. These are potential returns, not selected management actions.
#' # No optimiser or solver is needed to visualise the input values.
#'
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   spatial_returns <- data.frame(
#'     pu = sim$planning_units$id,
#'     action = "restore",
#'     profit = 20 + 5 * sim$planning_units$x
#'   )
#'
#'   p_spatial <- add_profit(p, profit = spatial_returns)
#'
#'   # Attach the registered restoration returns to the geometry.
#'   values <- subset(
#'     p_spatial$data$dist_profit,
#'     action == "restore",
#'     select = c("pu", "profit")
#'   )
#'   mapped <- merge(
#'     sim$planning_units,
#'     values,
#'     by.x = "id", by.y = "pu", all.x = TRUE
#'   )
#'
#'   # This map describes where restoration could generate economic
#'   # returns, not where optimisation has selected restoration.
#'   plot(mapped["profit"],
#'        main = "Potential economic return from restoration")
#' }
#'
#' @seealso
#' \code{\link{add_actions}},
#' \code{\link{add_objective_max_profit}},
#' \code{\link{add_objective_max_net_profit}},
#' \code{\link{add_effects}}
#'
#' @export
add_profit <- function(
    x,
    profit = NULL
) {
  .pa_assert_unconfigured(x, "dist_profit", "Profit", "add_profit()")
  # ---- checks: x
  assertthat::assert_that(!is.null(x), msg = "x is NULL")
  assertthat::assert_that(!is.null(x$data), msg = "x does not look like a multiscape Problem object")
  assertthat::assert_that(!is.null(x$data$pu), msg = "x$data$pu is missing. Run create_problem() first.")
  assertthat::assert_that(!is.null(x$data$dist_actions), msg = "No actions found. Run add_actions() first.")
  assertthat::assert_that(!is.null(x$data$actions), msg = "No action catalog found. Run add_actions() first.")

  x <- .pa_clone_data(x)
  pu   <- x$data$pu
  da   <- x$data$dist_actions
  acts <- x$data$actions

  # pu must have id; internal_id can be created if missing (defensive)
  assertthat::assert_that("id" %in% names(pu), msg = "x$data$pu must contain column 'id'.")
  if (!("internal_id" %in% names(pu))) {
    pu$internal_id <- seq_len(nrow(pu))
    x$data$pu <- pu
  }

  assertthat::assert_that(all(c("pu", "action") %in% names(da)), msg = "x$data$dist_actions must contain columns 'pu' and 'action'.")
  assertthat::assert_that("id" %in% names(acts), msg = "x$data$actions must contain column 'id'.")

  # enforce internal_id for actions (defensive)
  if (!("internal_id" %in% names(acts))) {
    acts$internal_id <- seq_len(nrow(acts))
    x$data$actions <- acts
  }

  pu_ids     <- pu$id
  action_ids <- as.character(acts$id)

  # base skeleton: all (pu, action) pairs currently in dist_actions
  base <- da[, c("pu", "action"), drop = FALSE]
  base$action <- as.character(base$action)

  # default profit
  base$profit <- 0

  # ---- fill profit from spec
  if (is.null(profit)) {

    # keep default 0

  } else if (is.numeric(profit) && !is.null(names(profit))) {

    # Named numeric vectors are always interpreted as action-level profit,
    # including vectors of length one. This branch must be evaluated before
    # the unnamed scalar branch.
    profit_names <- names(profit)

    if (
      anyNA(profit_names) ||
      any(!nzchar(profit_names))
    ) {
      stop(
        "Named `profit` vectors must have non-empty action ids.",
        call. = FALSE
      )
    }

    if (anyDuplicated(profit_names) > 0L) {
      duplicates <- unique(
        profit_names[duplicated(profit_names)]
      )

      stop(
        "profit contains duplicated action ids: ",
        paste(duplicates, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    unknown_actions <- setdiff(
      profit_names,
      action_ids
    )

    if (length(unknown_actions) > 0L) {
      stop(
        "profit contains unknown action ids: ",
        paste(unknown_actions, collapse = ", "),
        ".",
        call. = FALSE
      )
    }

    if (anyNA(profit) || any(!is.finite(profit))) {
      stop(
        "Named `profit` values must be finite and must not contain NA.",
        call. = FALSE
      )
    }

    base$profit <- as.numeric(
      profit[base$action]
    )
    base$profit[is.na(base$profit)] <- 0

  } else if (
    is.numeric(profit) &&
    length(profit) == 1L
  ) {

    if (is.na(profit) || !is.finite(profit)) {
      stop(
        "Scalar `profit` must be a finite numeric value.",
        call. = FALSE
      )
    }

    base$profit <- as.numeric(profit)

  } else if (inherits(profit, "data.frame")) {

    p <- profit

    # normalize legacy column naming
    if ("id" %in% names(p) && !("action" %in% names(p))) names(p)[names(p) == "id"] <- "action"

    # Case A: (action, profit)
    if (all(c("action", "profit") %in% names(p)) && !("pu" %in% names(p))) {

      p$action <- as.character(p$action)
      p$profit <- as.numeric(p$profit)

      if (!all(p$action %in% action_ids)) {
        bad <- unique(p$action[!p$action %in% action_ids])
        stop("profit contains unknown action ids: ", paste(bad, collapse = ", "), call. = FALSE)
      }
      if (anyDuplicated(p$action)) {
        stop("profit (action,profit) must have unique action rows.", call. = FALSE)
      }

      base <- dplyr::left_join(base, p, by = "action", suffix = c("", ".new"))
      if ("profit.new" %in% names(base)) {
        base$profit.new[is.na(base$profit.new)] <- 0
        base$profit <- base$profit.new
        base$profit.new <- NULL
      } else {
        base$profit <- as.numeric(base$profit)
      }

      # Case B: (pu, action, profit)
    } else if (all(c("pu", "action", "profit") %in% names(p))) {

      p$pu     <- as.numeric(p$pu)
      p$action <- as.character(p$action)
      p$profit <- as.numeric(p$profit)

      if (!all(p$pu %in% pu_ids)) {
        bad <- unique(p$pu[!p$pu %in% pu_ids])
        stop("profit contains unknown pu ids: ", paste(bad, collapse = ", "), call. = FALSE)
      }
      if (!all(p$action %in% action_ids)) {
        bad <- unique(p$action[!p$action %in% action_ids])
        stop("profit contains unknown action ids: ", paste(bad, collapse = ", "), call. = FALSE)
      }
      tmp <- p[, c("pu", "action")]
      if (nrow(dplyr::distinct(tmp)) != nrow(tmp)) {
        stop("profit has duplicate (pu, action) rows.", call. = FALSE)
      }

      feasible_key <- paste(base$pu, base$action, sep = "||")
      supplied_key <- paste(p$pu, p$action, sep = "||")
      infeasible <- !supplied_key %in% feasible_key

      if (any(infeasible)) {
        bad <- unique(
          paste0("(", p$pu[infeasible], ", ", p$action[infeasible], ")")
        )

        stop(
          "profit contains (pu, action) pair(s) that are not feasible: ",
          paste(bad, collapse = ", "),
          ".",
          call. = FALSE
        )
      }

      base <- dplyr::left_join(base, p, by = c("pu", "action"), suffix = c("", ".new"))
      if ("profit.new" %in% names(base)) {
        base$profit.new[is.na(base$profit.new)] <- 0
        base$profit <- base$profit.new
        base$profit.new <- NULL
      } else {
        base$profit <- as.numeric(base$profit)
      }

    } else {
      stop("Unsupported profit data.frame format. Use (action,profit) or (pu,action,profit).", call. = FALSE)
    }

  } else {
    stop("Unsupported type for 'profit'. Use NULL, numeric scalar, named numeric vector, or a data.frame.", call. = FALSE)
  }

  # ---- cleanup / validation
  base$profit <- as.numeric(base$profit)
  base$profit[is.na(base$profit)] <- 0

  if (!all(is.finite(base$profit))) stop("profit values must be finite.", call. = FALSE)

  # store only non-zero rows
  base <- base[base$profit != 0, , drop = FALSE]

  # ---- add internal ids
  pu_map   <- x$data$pu[, c("id", "internal_id")]
  acts_map <- x$data$actions[, c("id", "internal_id")]

  base$internal_pu     <- pu_map$internal_id[match(base$pu, pu_map$id)]
  base$internal_action <- acts_map$internal_id[match(base$action, acts_map$id)]

  dist_profit <- base[, c("pu", "action", "profit", "internal_pu", "internal_action"), drop = FALSE]

  # store
  x$data$dist_profit <- dist_profit

  x
}

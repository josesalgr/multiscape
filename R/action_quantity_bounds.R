# Resolve bounds by identifiers, never by the input row order.
.pa_action_quantity_bound <- function(pairs, spec, name) {
  if (is.numeric(spec) && length(spec) == 1L && is.null(names(spec))) {
    values <- rep(spec, nrow(pairs))
  } else if (is.numeric(spec) && !is.null(names(spec))) {
    if (anyNA(names(spec)) || any(!nzchar(names(spec))) || anyDuplicated(names(spec)) ||
        any(!names(spec) %in% pairs$action)) {
      stop("Invalid action names in `", name, "`.", call. = FALSE)
    }
    values <- unname(spec[match(pairs$action, names(spec))])
  } else if (is.data.frame(spec) && all(c("pu", "action", name) %in% names(spec))) {
    key <- paste(pairs$pu, pairs$action, sep = "::")
    supplied <- paste(spec$pu, spec$action, sep = "::")
    if (anyNA(spec$pu) || anyNA(spec$action) || anyDuplicated(supplied) ||
        any(!supplied %in% key)) {
      stop("Invalid or duplicate (pu, action) pairs in `", name, "`.", call. = FALSE)
    }
    values <- spec[[name]][match(key, supplied)]
  } else {
    stop("`", name, "` must be a numeric scalar, named action vector, or ",
         "data.frame with pu, action, and ", name, ".", call. = FALSE)
  }
  if (!is.numeric(values) || anyNA(values) || any(!is.finite(values)) ||
      any(values < 0) || any(values != floor(values)) || any(values > 2^53 - 1)) {
    stop("`", name, "` must supply a finite non-negative whole number ",
         "for every feasible pair (at most 2^53 - 1).", call. = FALSE)
  }
  as.numeric(values)
}

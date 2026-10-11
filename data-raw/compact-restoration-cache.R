# Prepare the analysis cache without changing stored decisions or results.
# This development script is excluded from the CRAN source package.
compact_restoration_solution_set <- function(solutions) {
  stopifnot(inherits(solutions, "SolutionSet"))
  excluded <- c("dist_effects_model", "dist_benefit_model", "dist_actions_model",
    "model_list", "model_index", "model_registry", "model_args", "mo_cache", "index")
  data <- solutions$problem$data[setdiff(names(solutions$problem$data), excluded)]
  data$has_model <- FALSE
  problem <- multiscape:::pproto(NULL, multiscape:::Problem, data = data)
  stored <- lapply(solutions$solution$solutions, function(one) {
    result <- multiscape:::pproto(NULL, multiscape:::Solution,
      solution = one$solution, summary = one$summary, diagnostics = one$diagnostics,
      method = one$method, meta = one$meta)
    # Assign after construction: pproto constructor arguments clone nested objects.
    result$problem <- problem
    result
  })
  solution_data <- solutions$solution
  solution_data$solutions <- stored
  meta <- solutions$meta
  vector_length <- length(solutions$problem$data$model_list$obj)
  if (vector_length == 0L) {
    vector_length <- max(vapply(stored, function(one) length(one$solution$vector), integer(1)))
  }
  meta$analysis_cache <- list(format_version = 1L,
    decision_vector_length = vector_length, excluded_problem_fields = excluded,
    scope = paste("Analysis-only cache: original decisions, objective values, summaries",
      "and solver diagnostics; one shared planning-data snapshot; no compiled solver models."))
  result <- multiscape:::pproto(NULL, multiscape:::SolutionSet,
    solution = solution_data, summary = solutions$summary, method = solutions$method,
    diagnostics = solutions$diagnostics, meta = meta)
  result$problem <- problem
  result
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 2L) stop("Usage: Rscript data-raw/compact-restoration-cache.R full.rds compact.rds")
  saveRDS(compact_restoration_solution_set(readRDS(args[1])), args[2], compress = "xz")
}

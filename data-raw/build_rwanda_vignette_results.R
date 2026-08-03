# Regenerate the compact results used by the Rwanda reserve-design vignette.
# This script requires Gurobi and a valid licence.

library(multiscape)
library(dplyr)
library(sf)

input_file <- file.path(
  "data-raw",
  "rwanda",
  "rwanda-reserve-inputs.rds"
)

if (!file.exists(input_file)) {
  stop(
    "Run data-raw/rwanda/prepare-data.R before rebuilding this analysis.",
    call. = FALSE
  )
}

rwanda_reserve <- readRDS(input_file)

problem <- create_problem(
  pu = rwanda_reserve$planning_units,
  features = rwanda_reserve$features,
  dist_features = rwanda_reserve$feature_distribution,
  cost = "cost",
  pu_id_col = "id"
) |>
  add_actions(
    actions = rwanda_reserve$actions,
    cost = 0
  ) |>
  add_effects(
    effects = rwanda_reserve$effects,
    effect_type = "after"
  ) |>
  add_constraint_targets_relative(0.30) |>
  add_constraint_locked_planning_units(
    locked_in = rwanda_reserve$planning_units$protected
  ) |>
  add_spatial_boundary(
    name = "boundary",
    include_self = TRUE,
    edge_factor = 0.5
  ) |>
  add_objective_min_cost(alias = "cost") |>
  add_objective_min_fragmentation_planning_units(
    relation_name = "boundary",
    alias = "fragmentation"
  )

table_directory <- file.path("vignettes", "results", "rwanda")
dir.create(table_directory, recursive = TRUE, showWarnings = FALSE)
problem_output <- capture.output(print(problem), type = "message")
writeLines(
  enc2utf8(problem_output),
  file.path(table_directory, "problem-summary.txt"),
  useBytes = TRUE
)

blm_values <- c(0, 1e-5, 1e-4, 1e-3, 1e-2, 2e-2, 5e-2, 1e-1, 1)

blm_problem <- problem |>
  set_method_weighted_sum(
    aliases = c("cost", "fragmentation"),
    runs = set_runs_manual(
      data.frame(
        weight_cost = 1,
        weight_fragmentation = blm_values
      )
    ),
    normalize_weights = FALSE,
    objective_scaling = FALSE
  ) |>
  set_solver_gurobi(
    gap_limit = 0,
    verbose = TRUE
  )

blm_solutions <- solve(blm_problem)

blm_objectives <- get_objectives(blm_solutions)

epsilon_limits <- seq(
  min(blm_objectives$fragmentation),
  max(blm_objectives$fragmentation),
  length.out = 8
)

epsilon_problem <- problem |>
  set_method_epsilon_constraint(
    primary = "cost",
    aliases = c("cost", "fragmentation"),
    runs = set_runs_manual(
      data.frame(eps_fragmentation = epsilon_limits)
    )
  ) |>
  set_solver_gurobi(
    gap_limit = 0,
    verbose = TRUE
  )

epsilon_solutions <- solve(epsilon_problem)

collect_results <- function(x) {
  list(
    runs = get_runs(x),
    objectives = get_objectives(x),
    actions = get_actions(x),
    targets = get_targets(x)
  )
}

rwanda_reserve_results <- list(
  blm = collect_results(blm_solutions),
  epsilon = collect_results(epsilon_solutions),
  blm_values = blm_values,
  epsilon_limits = epsilon_limits,
  generated_with = list(
    package_version = as.character(packageVersion("multiscape")),
    generated_at = as.character(Sys.time()),
    solver = "gurobi",
    gap_limit = 0,
    target = 0.30,
    protected_area_threshold = 0.75
  )
)

result_file <- file.path(
  "data-raw",
  "rwanda",
  "rwanda-reserve-results.rds"
)

saveRDS(
  rwanda_reserve_results,
  result_file,
  compress = "xz"
)

message("Saved local reproduction results: ", result_file)




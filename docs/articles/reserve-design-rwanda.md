# From reserve selection to multi-objective conservation planning

## Overview

Systematic conservation planning often begins with a minimum-set
question: which planning units should be included in a reserve network
so that all representation targets are achieved at minimum cost? Spatial
configuration can then be incorporated through a boundary length
modifier (BLM), which places cost and exposed reserve boundary in a
single weighted objective. This familiar formulation is useful when a
defensible BLM has already been selected, but it does not display the
full range of attainable compromises between economic and spatial
performance.

This vignette first reproduces that classical reserve-design workflow in
`multiscape`. It then changes the decision question. Instead of
selecting a BLM before optimization, cost and fragmentation are retained
as separate objectives and an epsilon-constraint design is used to
reveal their trade-off. The purpose is not to reproduce the full
functionality of dedicated conservation-planning software. The reserve
problem provides a recognizable reference from which to show how
`multiscape` supports explicit multi-objective analysis and comparison
of alternative spatial plans.

The analysis asks:

> Which additional planning units could complement Rwanda’s existing
> protected areas to represent at least 30% of every training feature,
> and what additional cost is required to obtain a more spatially
> compact reserve network?

## The MaPP Rwanda training case

The example adapts the Rwanda tutorial developed for the Marxan Planning
Platform (MaPP) by The Nature Conservancy (TNC 2024). The tutorial
contains 2,613 planning units, an existing protected-area layer, a Human
Modification Index-based cost surface, nine mammal distributions, and
four terrestrial ecoregions. Mammal distributions originate from global
habitat-suitability models (Rondinini et al. 2011), ecoregions from the
Terrestrial Ecoregions of the World (Olson et al. 2001), and human
modification from Kennedy et al. (2019) and Theobald et al. (2020).

The MaPP tutorial explicitly describes its narratives as fictional and
its features as an arbitrary subset selected for training. We retain
that interpretation here: the example demonstrates methodology and its
solutions must not be interpreted as conservation recommendations for
Rwanda. The source layers were projected to UTM zone 35S and intersected
with the planning units. A unit is treated as already protected when at
least 75% of its area overlaps the tutorial protected-area layer,
following the threshold used in the MaPP exercise.

The official tutorial archive is distributed by MaPP and can be obtained
from the [MaPP website](https://marxansolutions.org/marxanmapp/). The
underlying spatial layers are not redistributed with `multiscape`. To
reproduce the analysis, download and extract that archive, set
`MAPP_RWANDA_DIRECTORY` to the extracted directory, and run the
transparent preparation script supplied in
`data-raw/rwanda/prepare-data.R`. This creates a local working object;
it does not add the tutorial data to the installed package.

``` r

library(multiscape)
library(dplyr)
library(ggplot2)
library(sf)

Sys.setenv(
  MAPP_RWANDA_DIRECTORY = "path/to/extracted/MaPP-Tutorial-Rwanda"
)

source("data-raw/rwanda/prepare-data.R")
rwanda_reserve <- readRDS(
  "data-raw/rwanda/rwanda-reserve-inputs.rds"
)
```

The processed training case contains 2,613 planning units, of which 201
meet the tutorial’s existing-protection threshold, together with nine
mammal features and four terrestrial ecoregions. The complete list of
features and their spatial summaries can be reproduced with the code
above; it is not stored as package data.

The cost is retained in the scaled units supplied by the tutorial.
Larger values indicate more highly modified planning units and are
therefore less desirable for inclusion in the expanded network. Existing
protected units are locked into every solution and contribute toward the
representation targets.

``` r

planning_map <- rwanda_reserve$planning_units |>
  mutate(
    protection_status = if_else(
      protected,
      "Existing protected area",
      "Available for selection"
    )
  )

ggplot(planning_map) +
  geom_sf(aes(fill = cost), color = NA) +
  geom_sf(
    data = filter(planning_map, protected),
    fill = NA,
    color = "#1B7837",
    linewidth = 0.25
  ) +
  scale_fill_viridis_c(
    option = "C",
    name = "Human\nmodification"
  ) +
  coord_sf(datum = NA) +
  labs(
    title = "Planning context",
    subtitle = "Green outlines identify units with at least 75% protected-area coverage"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )
```

![Human-modification cost and existing protected planning units in the
MaPP Rwanda training
landscape.](figures/rwanda/reserve-design-rwanda-planning-context-1.png)

Human-modification cost and existing protected planning units in the
MaPP Rwanda training landscape.

The feature distributions are spatially heterogeneous. Some are
widespread, whereas others occur in only a small part of the planning
region. Amount is measured as the area of each feature within each
planning unit, so targets are based on represented area rather than
simple presence or absence.

``` r

feature_map <- rwanda_reserve$feature_distribution |>
  left_join(rwanda_reserve$features, by = c("feature" = "id")) |>
  group_by(feature) |>
  mutate(relative_amount = amount / max(amount)) |>
  ungroup() |>
  left_join(
    select(rwanda_reserve$planning_units, id, geometry),
    by = c("pu" = "id")
  ) |>
  st_as_sf()

ggplot(feature_map) +
  geom_sf(aes(fill = relative_amount), color = NA) +
  facet_wrap(~name, ncol = 4) +
  scale_fill_viridis_c(
    option = "C",
    limits = c(0, 1),
    name = "Relative\namount"
  ) +
  coord_sf(datum = NA) +
  theme_void(base_size = 9) +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 8)
  )
```

![Spatial distributions of the thirteen conservation features. Values
are normalized independently within each feature to emphasize spatial
pattern rather than differences in total
area.](figures/rwanda/reserve-design-rwanda-feature-distributions-1.png)

Spatial distributions of the thirteen conservation features. Values are
normalized independently within each feature to emphasize spatial
pattern rather than differences in total area.

## Define the reserve problem

Let \\i \in \mathcal{I}\\ denote planning units and \\j \in
\mathcal{J}\\ denote conservation features. The binary variable \\x_i\\
equals one when unit \\i\\ is included in the reserve network. In
`multiscape`, this decision is represented by a single `reserve` action.
Because there is only one candidate action, the action-assignment model
reduces to the classical binary site-selection problem.

The table supplied to
[`add_effects()`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
uses `effect_type = "after"`. Its multiplier of one means that selecting
the reserve action represents the baseline amount of each feature
contained in that unit. It does not describe a 100% ecological increase:
it describes the amount expected to be represented after the unit is
assigned to the reserve network.

``` r

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

problem
```

``` text
A multiscape object (<Problem>)
├─data
│├─planning units: <data.frame> (2613 total)
│├─costs: min: 3, max: 10000
│└─features: 13 total ("Albertine Rift montane forests", "Banded mongoose",
"Black rhinoceros", ...)
└─actions and effects
│├─actions: 1 total ("Reserve")
│├─feasible action pairs: 2613 feasible rows
│├─action costs: min: 0, max: 0
│├─effect data: 15078 rows
│├─effect mode: all zero
│└─profit data: none
└─spatial
│├─geometry: sf (2613 rows)
│├─coordinates: 2613 rows (x: 709263.1037..933932.07251, y:
9687210.70178..9884930.00179)
│└─relations: boundary (10174 edges, w: 0..4840.11063)
└─targets and constraints
│├─targets: 13 rows
│├─target preview: "Albertine Rift montane forests" >= 3.246e+09, "Banded
mongoose" >= 6.925e+09, "Black rhinoceros" >= 7.06e+09
│├─area constraints: none
│├─budget constraints: none
│├─planning-unit locks: 201 units (201 locked-in, 0 locked-out)
│└─action locks: none
└─model
│├─status: not built yet (will build in solve())
│├─objectives: 2 registered (cost, fragmentation)
│├─method: not set
│├─solver: not set (auto)
│└─checks: incomplete (multiple objectives registered but no MO method
selected)
# i Use `x$data` to inspect stored tables and model snapshots.
```

For every feature, the required amount is 30% of its amount across the
entire planning region:

\\ \sum\_{i \in \mathcal{I}} r\_{ij}x_i \geq 0.30\sum\_{i \in
\mathcal{I}}r\_{ij}, \qquad j \in \mathcal{J}, \\

where \\r\_{ij}\\ is the area of feature \\j\\ in unit \\i\\. Existing
protected units form the set \\\mathcal{P}\\ and are fixed through

\\ x_i=1, \qquad i \in \mathcal{P}. \\

The optimizer therefore identifies additions to the existing network
rather than designing a reserve system from an empty landscape.

## Minimum cost and the boundary length modifier

Without a spatial term, the classical minimum-set objective is

\\ \min C(x)=\sum_i c_i x_i, \\

where \\c_i\\ is the local Human Modification Index-based cost. This
formulation meets the representation requirements as cheaply as
possible, but inexpensive units can form a spatially dispersed network.

A BLM introduces a fragmentation expression \\F(x)\\. For adjacent units
\\(i,k) \in \mathcal{E}\\, let \\b\_{ik}\\ denote their shared boundary.
A boundary-style expression can be written as

\\ F(x)=\sum\_{(i,k)\in\mathcal{E}}b\_{ik}\|x_i-x_k\|, \\

with the external edge contribution handled by the stored boundary
relation. The BLM formulation is

\\ \min \\ C(x)+\lambda F(x), \\

subject to the same targets and locked-in units. Here \\\lambda\\ is the
BLM. It is an exchange coefficient between the units of cost and
boundary, not a percentage of importance.

The manual run design below keeps the coefficient of cost equal to one
and varies only the coefficient of fragmentation. Weight normalization
and objective scaling are deliberately disabled so that the optimized
expression has the traditional BLM interpretation.

``` r

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
```

The analyses shown below were solved with Gurobi to proven optimality
(`gap_limit = 0`) and without a time limit. They are not executed while
the vignette is built, because reproduction requires the external MaPP
archive and a licensed solver. The installed vignette contains only
publication figures: neither the spatial inputs nor the planning-unit
selections are distributed with `multiscape`. After preparing the data
locally, the complete analysis can be regenerated by running
`data-raw/build_rwanda_vignette_results.R` from the package source tree.

``` r

if (!requireNamespace("gurobi", quietly = TRUE)) {
  stop("Reproducing this analysis requires Gurobi and a valid licence.")
}

blm_solutions <- solve(blm_problem)
```

For transparency, the following excerpt is taken from one of these BLM
runs. It shows the solver version, exact optimality requirement,
termination status, and final zero MIP gap; the remaining runs are
summarized in the table below.

``` text
Gurobi Optimizer version 12.0.2 build v12.0.2rc0 (win64 - Windows 10.0 (19045.2))

CPU model: 12th Gen Intel(R) Core(TM) i7-12700H, instruction set [SSE2|AVX|AVX2]
Thread count: 14 physical cores, 20 logical processors, using up to 2 threads

Non-default parameters:
TimeLimit  2147483647
MIPGap  0
NodefileStart  0.5
LogToConsole  0
Threads  2

Optimize a model with 30736 rows, 12787 columns and 81271 nonzeros
Model fingerprint: 0xf08b2aba
Variable types: 7561 continuous, 5226 integer (5226 binary)
...
Solution count 10: 1.47127e+06 1.47127e+06 1.47128e+06 ... 1.47136e+06

Optimal solution found (tolerance 0.00e+00)
Best objective 1.471272000000e+06, best bound 1.471272000000e+06, gap 0.0000%
Set parameter Username
Set parameter LicenseID to value 2844238
Set parameter TimeLimit to value 2147483647
Set parameter MIPGap to value 0
Set parameter NodefileStart to value 0.5
Set parameter LogFile to value "output_log.txt"
Set parameter Threads to value 2
Academic license - for non-commercial use only - expires 2027-07-14
```

The run metadata and objective values should be inspected together. The
table below is the stored output from the seven runs used in this
vignette. The reported gap is the final relative MIP gap returned by
Gurobi.

``` r

blm_run_summary <- get_runs(blm_solutions) |>
  left_join(get_objectives(blm_solutions), by = "solution_id") |>
  mutate(blm = blm_values[run_id]) |>
  select(run_id, solution_id, blm, status, runtime, gap, cost, fragmentation)

blm_run_summary
```

| run_id | solution_id |   blm | status  | runtime | gap |    cost | fragmentation |
|-------:|------------:|------:|:--------|--------:|----:|--------:|--------------:|
|      1 |           1 | 0e+00 | optimal |   0.410 |   0 | 1471272 |       3132887 |
|      2 |           2 | 1e-05 | optimal |   1.585 |   0 | 1471272 |       3132887 |
|      3 |           3 | 1e-04 | optimal |   0.693 |   0 | 1471274 |       3101571 |
|      4 |           4 | 1e-03 | optimal |   0.848 |   0 | 1471276 |       3093331 |
|      5 |           5 | 1e-02 | optimal |   1.924 |   0 | 1472732 |       2833623 |
|      6 |           8 | 2e-02 | optimal |   0.793 |   0 | 1476289 |       2585514 |
|      7 |           9 | 5e-02 | optimal |   1.635 |   0 | 1496022 |       1984769 |
|      8 |           6 | 1e-01 | optimal |   4.481 |   0 | 1537824 |       1447814 |
|      9 |           7 | 1e+00 | optimal |  73.295 |   0 | 1743047 |        710325 |

Stored run metadata and objective values for the BLM analysis. {.table}

The resulting curve shows what is gained by increasing the BLM. Points
that overlap or are very close indicate ranges of coefficients that
induce the same or nearly the same reserve design. Because the
coefficient is scale dependent, its numerical value should not be
transferred unchanged to a landscape with a different cost surface,
projection, resolution, or boundary units.

``` r

ggplot(
  blm_results,
  aes(boundary_km, additional_cost)
) +
  geom_path(color = "grey70", linewidth = 0.5) +
  geom_point(color = "#2C7FB8", size = 2.8) +
  ggrepel::geom_text_repel(
    aes(label = blm_label),
    size = 3,
    min.segment.length = 0,
    seed = 500
  ) +
  scale_y_continuous(labels = function(x) paste0(round(x, 1), "%")) +
  labs(
    x = "Exposed boundary (km)",
    y = "Additional cost relative to the minimum-cost plan",
    title = "BLM calibration",
    subtitle = "Higher BLM values exchange additional cost for a more compact network"
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"))
```

![Cost and spatial-configuration outcomes obtained by changing the
boundary length modifier. Boundary is shown in its original spatial
units (converted to kilometres), while cost is expressed relative to the
minimum-cost solution (BLM =
0).](figures/rwanda/reserve-design-rwanda-plot-blm-1.png)

Cost and spatial-configuration outcomes obtained by changing the
boundary length modifier. Boundary is shown in its original spatial
units (converted to kilometres), while cost is expressed relative to the
minimum-cost solution (BLM = 0).

## Going beyond a fixed BLM

The BLM formulation is appropriate when an exchange rate between cost
and boundary is already defensible. When that exchange rate is
uncertain, keeping the objectives separate makes the attainable
compromises easier to inspect. For this purpose, cost remains the
primary objective and fragmentation is converted into an explicit upper
bound:

\\ \begin{aligned} \min \quad & C(x) \\ \text{subject to} \quad & F(x)
\leq \epsilon_r, \end{aligned} \\

in addition to the representation and locked-in constraints. Repeating
the model for different \\\epsilon_r\\ values traces the cost of
progressively more compact reserve designs. Epsilon-constraint does not
require cost and boundary to be expressed on a common numerical scale.

``` r

epsilon_limits <- seq(
  min(blm_results$fragmentation),
  max(blm_results$fragmentation),
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
```

The excerpt below is retained from the Gurobi output generated while
solving the exact epsilon-constraint analysis. It documents the
optimizer, termination status, objective value, and final optimality gap
without requiring the models to be solved again during website
construction.

``` text
Gurobi Optimizer version 12.0.2 build v12.0.2rc0 (win64 - Windows 10.0 (19045.2))

CPU model: 12th Gen Intel(R) Core(TM) i7-12700H, instruction set [SSE2|AVX|AVX2]
Thread count: 14 physical cores, 20 logical processors, using up to 2 threads

Non-default parameters:
TimeLimit  2147483647
MIPGap  0
NodefileStart  0.5
LogToConsole  0
Threads  2

Optimize a model with 30737 rows, 12787 columns and 91445 nonzeros
Model fingerprint: 0xfaba5e32
Variable types: 7561 continuous, 5226 integer (5226 binary)
Coefficient statistics:
  Matrix range     [1e+00, 1e+07]
  Objective range  [3e+00, 1e+04]
  Bounds range     [1e+00, 1e+00]

[branch-and-bound progress omitted]

Explored 2030 nodes (9904 simplex iterations) in 0.79 seconds (1.02 work units)
Thread count was 2 (of 20 available processors)

Solution count 10: 1.47127e+06 1.47128e+06 1.47128e+06 ... 1.47137e+06

Optimal solution found (tolerance 0.00e+00)
Best objective 1.471272000000e+06, best bound 1.471272000000e+06, gap 0.0000%
Saved local reproduction results: data-raw/rwanda/rwanda-reserve-results.rds
```

The manual epsilon limits span the range of fragmentation values
observed during the BLM calibration. This targets a decision-relevant
segment without requiring a difficult and potentially unrealistic
fragmentation-only extreme. In an applied analysis, the limits could
instead be supplied from spatial policy, implementation requirements, or
stakeholder deliberation. Each value is expressed directly in the units
of the stored boundary relation.

All eight epsilon runs returned feasible solutions within the requested
gap. Here `epsilon_fragmentation` is the imposed upper bound, whereas
`fragmentation` is the boundary value achieved by the corresponding
plan.

``` r

epsilon_run_summary <- get_runs(epsilon_solutions) |>
  left_join(get_objectives(epsilon_solutions), by = "solution_id") |>
  mutate(epsilon_fragmentation = epsilon_limits[run_id]) |>
  select(
    run_id,
    solution_id,
    epsilon_fragmentation,
    status,
    runtime,
    gap,
    cost,
    fragmentation
  )

epsilon_run_summary
```

| run_id | solution_id | epsilon_fragmentation | status | runtime | gap | cost | fragmentation |
|---:|---:|---:|:---|---:|---:|---:|---:|
| 1 | 1 | 710325 | optimal | 146.384 | 0 | 1743047 | 710325 |
| 2 | 2 | 1056406 | optimal | 351.242 | 0 | 1593609 | 1056232 |
| 3 | 3 | 1402486 | optimal | 61.703 | 0 | 1542810 | 1402407 |
| 4 | 4 | 1748566 | optimal | 6.189 | 0 | 1511220 | 1748458 |
| 5 | 5 | 2094646 | optimal | 26.266 | 0 | 1490829 | 2094595 |
| 6 | 6 | 2440727 | optimal | 1.932 | 0 | 1479401 | 2439845 |
| 7 | 7 | 2786807 | optimal | 3.319 | 0 | 1473229 | 2786757 |
| 8 | 8 | 3132887 | optimal | 0.790 | 0 | 1471272 | 3132887 |

Stored run metadata, epsilon limits, and objective values for the
epsilon-constraint analysis. {.table}

``` r

comparison_data <- bind_rows(
  blm_results |>
    transmute(
      solution_id,
      additional_cost,
      boundary_km,
      method = "BLM weighted sum"
    ),
  epsilon_results |>
    transmute(
      solution_id,
      additional_cost,
      boundary_km,
      method = "Epsilon-constraint"
    )
)

ggplot(
  comparison_data,
  aes(
    boundary_km,
    additional_cost,
    color = method,
    shape = method
  )
) +
  geom_point(size = 3, alpha = 0.9) +
  scale_color_manual(
    values = c(
      "BLM weighted sum" = "#D95F02",
      "Epsilon-constraint" = "#1B9E77"
    )
  ) +
  scale_x_continuous(labels = function(x) paste0(round(x, 1), "%")) +
  scale_y_continuous(labels = function(x) paste0(round(x, 1), "%")) +
  labs(
    x = "Exposed boundary (km)",
    y = "Additional cost relative to the minimum-cost plan",
    color = NULL,
    shape = NULL,
    title = "Two ways to express the same planning tension"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )
```

![Solutions generated using fixed BLM coefficients and explicit epsilon
limits. Moving toward a lower exposed boundary requires progressively
greater
cost.](figures/rwanda/reserve-design-rwanda-compare-methods-1.png)

Solutions generated using fixed BLM coefficients and explicit epsilon
limits. Moving toward a lower exposed boundary requires progressively
greater cost.

The two methods answer different questions. A BLM solution is
conditional on a specified exchange coefficient. An epsilon solution
answers a directly bounded question such as: what is the least-cost plan
if exposed boundary may not exceed this value? Exploring several bounds
supports an a posteriori workflow in which decision makers inspect the
consequences before selecting a plan. A single policy-derived bound
would instead constitute an a priori use of the same method.

## Compare representative reserve designs

Objective values alone do not reveal whether two plans select the same
places. We therefore retain three representative epsilon solutions: the
least-cost plan, the most compact plan, and an observed compromise
closest to the ideal point after range normalization. The compromise is
a descriptive reference, not an automatically preferred decision.

The maps use
[`plot_spatial_actions()`](https://josesalgr.github.io/multiscape/reference/plot_spatial_actions.md),
the package function for mapping actions stored in a `SolutionSet`. Its
`nrow` and `ncol` arguments control the facet arrangement when several
solutions are displayed; here the three plans are placed in two columns.
A second layer marks the units that were already protected,
distinguishing inherited protection from additions chosen by the
optimizer.

``` r

action_plot <- plot_spatial_actions(
  epsilon_solutions,
  solutions = unname(representative_ids),
  layout = "single",
  ncol = 2,
  fill_values = c(reserve = "#F39C12"),
  base_fill = "#F2F2F2",
  base_alpha = 1
)

action_plot +
  facet_wrap(
    ~solution_id,
    ncol = 2,
    labeller = as_labeller(
      setNames(names(representative_ids), representative_ids)
    )
  ) +
  geom_sf(
    data = filter(rwanda_reserve$planning_units, protected),
    fill = "#238B45",
    color = NA
  ) +
  labs(title = "Alternative reserve designs")
```

![Representative reserve designs from the epsilon-constraint frontier.
Existing protected units occur in every plan; orange units are additions
selected to meet the 30% targets under different spatial
limits.](figures/rwanda/reserve-design-rwanda-representative-maps-1.png)

Representative reserve designs from the epsilon-constraint frontier.
Existing protected units occur in every plan; orange units are additions
selected to meet the 30% targets under different spatial limits.

The maps distinguish economic and spatial trade-offs from changes in
location. Two plans can have similar objective values while prescribing
different additions to the protected-area network. Conversely, some
units may occur consistently because they contain restricted features,
complement the existing network, or provide an efficient spatial
connection.

Selection frequency summarizes this stability across all epsilon
solutions. It should not be interpreted as a probability of protection:
it is the number or proportion of analyzed planning scenarios in which a
unit was selected.

``` r

frequency_data <- action_results |>
  filter(selected == 1) |>
  count(pu, name = "selected_runs") |>
  mutate(frequency = selected_runs / nrow(epsilon_results))

frequency_map <- rwanda_reserve$planning_units |>
  left_join(frequency_data, by = c("id" = "pu")) |>
  mutate(
    frequency = coalesce(frequency, 0),
    frequency_available = if_else(protected, NA_real_, frequency)
  )

ggplot(frequency_map) +
  geom_sf(aes(fill = frequency_available), color = NA) +
  geom_sf(
    data = filter(frequency_map, protected),
    fill = "#238B45",
    color = NA
  ) +
  scale_fill_viridis_c(
    option = "B",
    limits = c(0, 1),
    na.value = "#238B45",
    name = "Selection\nfrequency"
  ) +
  coord_sf(datum = NA) +
  labs(
    title = "Spatial stability across the frontier",
    subtitle = "Green units were already protected and locked into every solution"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )
```

![Selection frequency across the epsilon-constraint solutions. Existing
protected units are shown separately because they were locked into every
plan.](figures/rwanda/reserve-design-rwanda-selection-frequency-1.png)

Selection frequency across the epsilon-constraint solutions. Existing
protected units are shown separately because they were locked into every
plan.

## Interpretation

The minimum-set, BLM, and epsilon-constraint formulations are not
competing definitions of the reserve problem. They represent
progressively different preference statements. Minimum cost assumes that
the representation targets and existing protected network are sufficient
to define feasibility. The BLM adds a pre-specified exchange rate
between economic and spatial performance. Epsilon-constraint instead
treats spatial configuration as an explicit limit and can be repeated to
characterize the consequences of alternative limits.

This distinction illustrates the broader role of `multiscape`. A
familiar reserve-selection model can be retained when it matches the
decision context, while its constituent criteria can also be registered
as separate objectives when trade-offs should remain visible. The
resulting frontier does not choose a reserve design on behalf of
decision makers. It organizes a set of feasible, interpretable
alternatives that all satisfy the same 30% representation requirements.

## References

TNC. 2024. *The Marxan Planning Platform: Tutorial (Rwanda).* Global
Science, The Nature Conservancy, Arlington, Virginia, USA.
<https://marxanplanning.org>.

Kennedy, C. M., et al. 2019. Managing the middle: a shift in
conservation priorities based on the global human modification gradient.
*Global Change Biology* 25: 811-826.
<https://doi.org/10.1111/gcb.14549>.

Olson, D. M., et al. 2001. Terrestrial Ecoregions of the World: A New
Map of Life on Earth. *BioScience* 51: 933-938.
<https://doi.org/10.1641/0006-3568(2001)051%5B0933:TEOTWA%5D2.0.CO;2>.

Rondinini, C., et al. 2011. Global habitat suitability models of
terrestrial mammals. *Philosophical Transactions of the Royal Society B*
366: 2633-2641. <https://doi.org/10.1098/rstb.2011.0113>.

Theobald, D. M., et al. 2020. Earth transformed: detailed mapping of
global human modification from 1990 to 2017. *Earth System Science Data*
12: 1953-1972. <https://doi.org/10.5194/essd-12-1953-2020>.

# Package index

## Build and solve problems

Core workflow to create a planning problem, configure it, and solve it.

- [`create_problem()`](https://josesalgr.github.io/multiscape/reference/create_problem.md)
  : Create a planning problem input object
- [`solve()`](https://josesalgr.github.io/multiscape/reference/solve.md)
  : Solve a planning problem

## Actions, effects and profits

Define feasible actions, their effects, and optional profits.

- [`add_actions()`](https://josesalgr.github.io/multiscape/reference/add_actions.md)
  : Add management actions to a planning problem
- [`add_effects()`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
  : Add action effects to a planning problem
- [`add_benefits()`](https://josesalgr.github.io/multiscape/reference/add_benefits.md)
  : Add benefits
- [`add_losses()`](https://josesalgr.github.io/multiscape/reference/add_losses.md)
  : Add losses
- [`add_profit()`](https://josesalgr.github.io/multiscape/reference/add_profit.md)
  : Add profit to a planning problem

## Constraints

Define target requirements, area limits, budgets, and locking
constraints.

- [`add_constraint_targets_absolute()`](https://josesalgr.github.io/multiscape/reference/add_constraint_targets_absolute.md)
  : Add absolute targets
- [`add_constraint_targets_relative()`](https://josesalgr.github.io/multiscape/reference/add_constraint_targets_relative.md)
  : Add relative targets
- [`add_constraint_area()`](https://josesalgr.github.io/multiscape/reference/add_constraint_area.md)
  : Add area constraint
- [`add_constraint_budget()`](https://josesalgr.github.io/multiscape/reference/add_constraint_budget.md)
  : Add budget constraint
- [`add_constraint_locked_actions()`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_actions.md)
  : Add locked action decisions to a planning problem
- [`add_constraint_locked_planning_units()`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_planning_units.md)
  : Add locked planning units to a problem

## Spatial relations

Register boundary and graph-based spatial relations from tables,
polygons, or coordinates.

- [`add_spatial_relations()`](https://josesalgr.github.io/multiscape/reference/add_spatial_relations.md)
  : Add spatial relations
- [`add_spatial_boundary()`](https://josesalgr.github.io/multiscape/reference/add_spatial_boundary.md)
  : Add spatial boundary-length relations
- [`add_spatial_rook()`](https://josesalgr.github.io/multiscape/reference/add_spatial_rook.md)
  : Add rook adjacency from polygons
- [`add_spatial_queen()`](https://josesalgr.github.io/multiscape/reference/add_spatial_queen.md)
  : Add queen adjacency from polygons
- [`add_spatial_knn()`](https://josesalgr.github.io/multiscape/reference/add_spatial_knn.md)
  : Add k-nearest-neighbours spatial relations
- [`add_spatial_distance()`](https://josesalgr.github.io/multiscape/reference/add_spatial_distance.md)
  : Add distance-threshold spatial relations

## Atomic objectives

Register objectives that can be solved individually or combined in
multi-objective workflows.

- [`add_objective_min_cost()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_cost.md)
  : Add objective: minimize cost
- [`add_objective_max_benefit()`](https://josesalgr.github.io/multiscape/reference/add_objective_max_benefit.md)
  : Add objective: maximize benefit
- [`add_objective_min_loss()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_loss.md)
  : Add objective: minimize loss
- [`add_objective_max_profit()`](https://josesalgr.github.io/multiscape/reference/add_objective_max_profit.md)
  : Add objective: maximize profit
- [`add_objective_max_net_profit()`](https://josesalgr.github.io/multiscape/reference/add_objective_max_net_profit.md)
  : Add objective: maximize net profit
- [`add_objective_min_fragmentation_planning_units()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_planning_units.md)
  : Add objective: minimize planning-unit fragmentation
- [`add_objective_min_fragmentation_action()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_action.md)
  : Add objective: minimize action fragmentation
- [`add_objective_min_intervention_impact()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_intervention_impact.md)
  : Add objective: minimize intervention impact

## Solver configuration

Store solver and runtime options before calling solve().

- [`set_solver()`](https://josesalgr.github.io/multiscape/reference/set_solver.md)
  : Configure solver settings
- [`set_solver_gurobi()`](https://josesalgr.github.io/multiscape/reference/set_solver_gurobi.md)
  : Configure Gurobi solver settings
- [`set_solver_cplex()`](https://josesalgr.github.io/multiscape/reference/set_solver_cplex.md)
  : Configure CPLEX solver settings
- [`set_solver_cbc()`](https://josesalgr.github.io/multiscape/reference/set_solver_cbc.md)
  : Configure CPLEX solver settings
- [`set_solver_symphony()`](https://josesalgr.github.io/multiscape/reference/set_solver_symphony.md)
  : Configure SYMPHONY solver settings

## Multi-objective methods

Configure weighted-sum, epsilon-constraint, and AUGMECON workflows.

- [`set_method_weighted_sum()`](https://josesalgr.github.io/multiscape/reference/set_method_weighted_sum.md)
  : Set the weighted-sum multi-objective method
- [`set_method_epsilon_constraint()`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md)
  : Set the epsilon-constraint multi-objective method
- [`set_method_augmecon()`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md)
  : Set the AUGMECON multi-objective method

## Multi-objective run configuration

Define automatic or manual run designs and execution controls for
multi-objective workflows.

- [`set_runs_grid()`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
  : Define an automatic multi-objective run grid
- [`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md)
  : Define a manual multi-objective run design
- [`set_runs_control()`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md)
  : Control multi-objective run behavior

## Results and extraction

Extract run metadata, objective values, and solution-level results.

- [`get_runs()`](https://josesalgr.github.io/multiscape/reference/get_runs.md)
  : Get run-level metadata from a solution set
- [`get_objectives()`](https://josesalgr.github.io/multiscape/reference/get_objectives.md)
  : Get objective values from a solution set
- [`get_planning_units()`](https://josesalgr.github.io/multiscape/reference/get_planning_units.md)
  : Get planning-unit results from a solution set
- [`get_actions()`](https://josesalgr.github.io/multiscape/reference/get_actions.md)
  : Get action results from a solution set
- [`get_features()`](https://josesalgr.github.io/multiscape/reference/get_features.md)
  : Get feature summary from a solution set
- [`get_targets()`](https://josesalgr.github.io/multiscape/reference/get_targets.md)
  : Get target achievement summary from a solution set

## Solution-set management

Filter, combine, and remove repeated solutions while preserving
SolutionSet consistency.

- [`solution_filter()`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)
  : Filter solutions in a solution set
- [`solution_append()`](https://josesalgr.github.io/multiscape/reference/solution_append.md)
  : Append solutions from another solution set
- [`solution_unique()`](https://josesalgr.github.io/multiscape/reference/solution_unique.md)
  : Keep unique solutions in a solution set

## Frontier analysis

Characterize objective ranges and distances to observed reference
points.

- [`frontier_extremes()`](https://josesalgr.github.io/multiscape/reference/frontier_extremes.md)
  : Find objective-wise extreme solutions
- [`frontier_distances()`](https://josesalgr.github.io/multiscape/reference/frontier_distances.md)
  : Compute distances to observed ideal or nadir points
- [`frontier_knee()`](https://josesalgr.github.io/multiscape/reference/frontier_knee.md)
  : Identify knee solutions on an observed Pareto frontier

## Selection analysis

Analyze the recurrence and structural similarity of planning-unit and
action assignments.

- [`selection_frequency()`](https://josesalgr.github.io/multiscape/reference/selection_frequency.md)
  : Calculate selection frequency across solutions
- [`selection_similarity()`](https://josesalgr.github.io/multiscape/reference/selection_similarity.md)
  : Calculate structural similarity among solutions

## Plotting

Visualize spatial outputs and multi-objective trade-offs.

- [`plot_spatial_planning_units()`](https://josesalgr.github.io/multiscape/reference/plot_spatial_planning_units.md)
  : Plot selected planning units in space
- [`plot_spatial_actions()`](https://josesalgr.github.io/multiscape/reference/plot_spatial_actions.md)
  : Plot selected actions in space
- [`plot_spatial_features()`](https://josesalgr.github.io/multiscape/reference/plot_spatial_features.md)
  : Plot spatial feature values from a solution set
- [`plot_tradeoff()`](https://josesalgr.github.io/multiscape/reference/plot_tradeoff.md)
  : Plot trade-offs from a solution set

## Advanced functions

Advanced utilities for inspecting or compiling optimization models.

- [`compile_model()`](https://josesalgr.github.io/multiscape/reference/compile_model.md)
  : Compile the optimization model stored in a Problem

## Classes

Public classes used across the package.

- [`problem-class`](https://josesalgr.github.io/multiscape/reference/problem-class.md)
  [`Problem`](https://josesalgr.github.io/multiscape/reference/problem-class.md)
  : Problem class
- [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  [`SolutionSet`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  : SolutionSet class

## Data

Simulated datasets distributed with the package.

- [`sim_dist_features`](https://josesalgr.github.io/multiscape/reference/sim_dist_features.md)
  : Simulated feature distribution
- [`sim_features`](https://josesalgr.github.io/multiscape/reference/sim_features.md)
  : Simulated features
- [`sim_pu`](https://josesalgr.github.io/multiscape/reference/sim_pu.md)
  : Simulated planning units
- [`sim_pu_sf`](https://josesalgr.github.io/multiscape/reference/sim_pu_sf.md)
  : Simulated planning units
- [`load_sim_features_raster()`](https://josesalgr.github.io/multiscape/reference/load_sim_features_raster.md)
  : Example feature raster

## Deprecated functions

Deprecated functions kept for backwards compatibility.

- [`add_constraint_locked_pu()`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_pu.md)
  **\[obsoleta\]** : Add locked planning units to a problem
- [`add_objective_min_fragmentation_pu()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_pu.md)
  **\[obsoleta\]** : Add objective: minimize planning-unit fragmentation
- [`get_pu()`](https://josesalgr.github.io/multiscape/reference/get_pu.md)
  **\[obsoleta\]** : Get planning-unit results from a solution set
- [`plot_spatial_pu()`](https://josesalgr.github.io/multiscape/reference/plot_spatial_pu.md)
  **\[obsoleta\]** : Plot selected planning units in space
- [`run_grid()`](https://josesalgr.github.io/multiscape/reference/run_grid.md)
  **\[obsoleta\]** : Define an automatic multi-objective run grid
- [`run_manual()`](https://josesalgr.github.io/multiscape/reference/run_manual.md)
  **\[obsoleta\]** : Define a manual multi-objective run design
- [`mo_control()`](https://josesalgr.github.io/multiscape/reference/mo_control.md)
  **\[obsoleta\]** : Control multi-objective run behavior

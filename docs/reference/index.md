# Package index

## Create a planning problem

Create the core planning problem from planning units, features, costs,
and optional spatial data.

- [`create_problem()`](https://josesalgr.github.io/multiscape/reference/create_problem.md)
  : Create a planning problem input object

## Management actions and outcomes

Define feasible management actions and their ecological and economic
consequences.

- [`add_actions()`](https://josesalgr.github.io/multiscape/reference/add_actions.md)
  : Add management actions to a planning problem
- [`add_action_sets()`](https://josesalgr.github.io/multiscape/reference/add_action_sets.md)
  : Register sets of management actions
- [`add_effects()`](https://josesalgr.github.io/multiscape/reference/add_effects.md)
  : Add action effects to a planning problem
- [`add_profit()`](https://josesalgr.github.io/multiscape/reference/add_profit.md)
  : Add profit to a planning problem

## Targets and constraints

Specify representation targets, resource limits, and fixed planning-unit
or action decisions.

- [`add_constraint_targets_absolute()`](https://josesalgr.github.io/multiscape/reference/add_constraint_targets_absolute.md)
  : Add absolute targets
- [`add_constraint_targets_relative()`](https://josesalgr.github.io/multiscape/reference/add_constraint_targets_relative.md)
  : Add relative targets
- [`add_constraint_area()`](https://josesalgr.github.io/multiscape/reference/add_constraint_area.md)
  : Add area constraint
- [`add_constraint_budget()`](https://josesalgr.github.io/multiscape/reference/add_constraint_budget.md)
  : Add budget constraint
- [`add_constraint_action_cardinality()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_cardinality.md)
  : Constrain the number of actions selected per planning unit
- [`add_constraint_action_requires()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_requires.md)
  : Require companion actions in each planning unit
- [`add_constraint_action_excludes()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_excludes.md)
  : Make actions mutually exclusive within each planning unit
- [`add_constraint_action_together()`](https://josesalgr.github.io/multiscape/reference/add_constraint_action_together.md)
  : Select actions together within each planning unit
- [`add_constraint_locked_actions()`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_actions.md)
  : Add locked action decisions to a planning problem
- [`add_constraint_locked_planning_units()`](https://josesalgr.github.io/multiscape/reference/add_constraint_locked_planning_units.md)
  : Add locked planning units to a problem

## Spatial relationships

Define and store neighborhood, boundary, distance, and user-supplied
relationships among planning units.

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

Add ecological, economic, and spatial objectives to the planning
problem.

- [`add_objective_min_cost()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_cost.md)
  : Add objective: minimize cost
- [`add_objective_max_effect()`](https://josesalgr.github.io/multiscape/reference/add_objective_max_effect.md)
  : Add objective: maximize signed effect
- [`add_objective_min_effect()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_effect.md)
  : Add objective: minimise signed effect
- [`add_objective_max_profit()`](https://josesalgr.github.io/multiscape/reference/add_objective_max_profit.md)
  : Add objective: maximize profit
- [`add_objective_max_net_profit()`](https://josesalgr.github.io/multiscape/reference/add_objective_max_net_profit.md)
  : Add objective: maximize net profit
- [`add_objective_min_fragmentation_planning_units()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_planning_units.md)
  : Add objective: minimise planning-unit fragmentation
- [`add_objective_min_fragmentation_action()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_action.md)
  : Add objective: minimise action fragmentation

## Multi-objective methods and run designs

Choose how multiple objectives are explored and define the combinations
of weights or constraints to evaluate.

- [`set_method_weighted_sum()`](https://josesalgr.github.io/multiscape/reference/set_method_weighted_sum.md)
  : Set the weighted-sum multi-objective method
- [`set_method_epsilon_constraint()`](https://josesalgr.github.io/multiscape/reference/set_method_epsilon_constraint.md)
  : Set the epsilon-constraint multi-objective method
- [`set_method_augmecon()`](https://josesalgr.github.io/multiscape/reference/set_method_augmecon.md)
  : Set the AUGMECON multi-objective method
- [`set_runs_grid()`](https://josesalgr.github.io/multiscape/reference/set_runs_grid.md)
  : Define an automatic multi-objective run grid
- [`set_runs_manual()`](https://josesalgr.github.io/multiscape/reference/set_runs_manual.md)
  : Define a manual multi-objective run design
- [`set_runs_control()`](https://josesalgr.github.io/multiscape/reference/set_runs_control.md)
  : Control multi-objective run behavior

## Solvers and optimization

Select and configure a mixed-integer programming solver, then solve the
planning problem.

- [`set_solver()`](https://josesalgr.github.io/multiscape/reference/set_solver.md)
  : Configure solver settings
- [`set_solver_gurobi()`](https://josesalgr.github.io/multiscape/reference/set_solver_gurobi.md)
  : Configure Gurobi solver settings
- [`set_solver_cplex()`](https://josesalgr.github.io/multiscape/reference/set_solver_cplex.md)
  : Configure CPLEX solver settings
- [`set_solver_cbc()`](https://josesalgr.github.io/multiscape/reference/set_solver_cbc.md)
  : Configure CBC solver settings
- [`set_solver_symphony()`](https://josesalgr.github.io/multiscape/reference/set_solver_symphony.md)
  : Configure SYMPHONY solver settings
- [`solve()`](https://josesalgr.github.io/multiscape/reference/solve.md)
  : Solve a planning problem

## Inspect solutions

Extract run metadata, objective values, spatial decisions, features, and
target outcomes from stored solutions.

- [`get_runs()`](https://josesalgr.github.io/multiscape/reference/get_runs.md)
  : Get run-level metadata from a solution set
- [`get_objectives()`](https://josesalgr.github.io/multiscape/reference/get_objectives.md)
  : Get objective values from a solution set
- [`get_planning_units()`](https://josesalgr.github.io/multiscape/reference/get_planning_units.md)
  : Get planning-unit results from a solution set
- [`get_actions()`](https://josesalgr.github.io/multiscape/reference/get_actions.md)
  : Get action results from a solution set
- [`get_solution_states()`](https://josesalgr.github.io/multiscape/reference/get_solution_states.md)
  : Get planning-unit states from stored solutions
- [`get_features()`](https://josesalgr.github.io/multiscape/reference/get_features.md)
  : Get feature summary from a solution set
- [`get_targets()`](https://josesalgr.github.io/multiscape/reference/get_targets.md)
  : Get target achievement summary from a solution set
- [`get_action_sets()`](https://josesalgr.github.io/multiscape/reference/get_action_sets.md)
  : Inspect registered action sets

## Manage solution sets

Filter, combine, and remove duplicate alternatives before analysis or
reporting.

- [`solution_filter()`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)
  : Filter solutions in a solution set
- [`solution_append()`](https://josesalgr.github.io/multiscape/reference/solution_append.md)
  : Append solutions from another solution set
- [`solution_unique()`](https://josesalgr.github.io/multiscape/reference/solution_unique.md)
  : Keep unique solutions in a solution set

## Objective-space analysis

Characterize performance trade-offs, empirical extremes, distances,
knees, and neighboring alternatives in objective space.

- [`frontier_extremes()`](https://josesalgr.github.io/multiscape/reference/frontier_extremes.md)
  : Find objective-wise extreme solutions
- [`frontier_distances()`](https://josesalgr.github.io/multiscape/reference/frontier_distances.md)
  : Compute distances to observed ideal or nadir points
- [`frontier_knee()`](https://josesalgr.github.io/multiscape/reference/frontier_knee.md)
  : Identify knee solutions on an observed Pareto frontier
- [`frontier_neighbors()`](https://josesalgr.github.io/multiscape/reference/frontier_neighbors.md)
  : Identify neighboring solutions in objective space

## Decision-space analysis

Quantify recurrence, similarity, and consistency in spatial decisions
across alternative solutions.

- [`selection_frequency()`](https://josesalgr.github.io/multiscape/reference/selection_frequency.md)
  : Calculate selection frequency across solutions
- [`selection_similarity()`](https://josesalgr.github.io/multiscape/reference/selection_similarity.md)
  : Calculate structural similarity among solutions
- [`selection_consistency()`](https://josesalgr.github.io/multiscape/reference/selection_consistency.md)
  : Summarize consistency of planning-unit states

## Objective-decision linkage

Relate changes in objective performance to changes in spatial
prescriptions and identify informative solution contrasts.

- [`linkage_distances()`](https://josesalgr.github.io/multiscape/reference/linkage_distances.md)
  : Compare objective and decision distances
- [`linkage_transition()`](https://josesalgr.github.io/multiscape/reference/linkage_transition.md)
  : Describe the transition between two solutions
- [`linkage_turnover()`](https://josesalgr.github.io/multiscape/reference/linkage_turnover.md)
  : Measure decision turnover along an objective-space neighborhood
- [`linkage_contrasts()`](https://josesalgr.github.io/multiscape/reference/linkage_contrasts.md)
  : Select informative solution contrasts

## Visualize results

Plot objective trade-offs, planning-unit selections, management actions,
and spatial feature distributions.

- [`plot_tradeoff()`](https://josesalgr.github.io/multiscape/reference/plot_tradeoff.md)
  : Plot trade-offs from a solution set
- [`plot_spatial_planning_units()`](https://josesalgr.github.io/multiscape/reference/plot_spatial_planning_units.md)
  : Plot selected planning units in space
- [`plot_spatial_actions()`](https://josesalgr.github.io/multiscape/reference/plot_spatial_actions.md)
  : Plot selected actions in space
- [`plot_spatial_features()`](https://josesalgr.github.io/multiscape/reference/plot_spatial_features.md)
  : Plot spatial feature values from a solution set

## Core objects

Classes used to represent planning problems and their resulting solution
sets.

- [`problem-class`](https://josesalgr.github.io/multiscape/reference/problem-class.md)
  [`Problem`](https://josesalgr.github.io/multiscape/reference/problem-class.md)
  : Problem class
- [`solutionset-class`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  [`SolutionSet`](https://josesalgr.github.io/multiscape/reference/solutionset-class.md)
  : SolutionSet class

## Advanced model inspection

Compile and inspect the underlying optimization model.

- [`compile_model()`](https://josesalgr.github.io/multiscape/reference/compile_model.md)
  : Compile the optimization model stored in a Problem

## Example data

Three complete entry points: a compact simulated example, the Meseta
tutorial, and the integrated ecosystem-services example.

- [`load_sim_multiaction()`](https://josesalgr.github.io/multiscape/reference/load_sim_multiaction.md)
  : Load the simulated spatial multi-action example
- [`load_meseta()`](https://josesalgr.github.io/multiscape/reference/load_meseta.md)
  : Load the Meseta Iberica spatial action example
- [`load_ecosystem_services()`](https://josesalgr.github.io/multiscape/reference/load_ecosystem_services.md)
  : Load the ecosystem-services spatial example

## Historical data access

Earlier data objects and the raster-only loader remain available for
compatibility. Prefer the complete example loaders above.

- [`sim_dist_features`](https://josesalgr.github.io/multiscape/reference/sim_dist_features.md)
  : Simulated feature distribution
- [`sim_features`](https://josesalgr.github.io/multiscape/reference/sim_features.md)
  : Simulated features
- [`sim_multiaction`](https://josesalgr.github.io/multiscape/reference/sim_multiaction.md)
  : Simulated spatial multi-action planning inputs
- [`sim_pu`](https://josesalgr.github.io/multiscape/reference/sim_pu.md)
  : Simulated planning units
- [`sim_pu_sf`](https://josesalgr.github.io/multiscape/reference/sim_pu_sf.md)
  : Simulated planning units
- [`load_sim_features_raster()`](https://josesalgr.github.io/multiscape/reference/load_sim_features_raster.md)
  : Example feature raster

## Deprecated functions

Functions retained temporarily for backward compatibility.

- [`add_benefits()`](https://josesalgr.github.io/multiscape/reference/add_benefits.md)
  : Add benefits
- [`add_losses()`](https://josesalgr.github.io/multiscape/reference/add_losses.md)
  : Add losses
- [`add_objective_max_benefit()`](https://josesalgr.github.io/multiscape/reference/add_objective_max_benefit.md)
  : Deprecated benefit objective
- [`add_objective_min_loss()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_loss.md)
  : Deprecated objective: minimize loss
- [`add_objective_min_intervention_impact()`](https://josesalgr.github.io/multiscape/reference/add_objective_min_intervention_impact.md)
  **\[obsoleta\]** : Add objective: minimize intervention impact
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

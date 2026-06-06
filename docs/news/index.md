# Changelog

## multiscape 1.1.0

### Solution architecture

- Simplified the public result architecture so that
  [`solve()`](https://josesalgr.github.io/multiscape/reference/solve.md)
  consistently returns a `SolutionSet`, including for single-objective
  problems.
- Removed the internal `Solution` class from the public API and
  documentation. Individual run-level solutions remain available only as
  internal components of a `SolutionSet`.
- Added stable `solution_id` identifiers to distinguish stored solutions
  from attempted runs identified by `run_id`.
- Updated run, solution, and summary tables to preserve `run_id` and
  `solution_id` consistently across extraction and analysis functions.
- Improved internal finalization of solution metadata and identifiers
  after solving.
- Updated `SolutionSet` printing and documentation to reflect the
  distinction between run attempts and stored solutions.

### Simple conservation-planning workflow

- Added automatic support for simple conservation-planning problems when
  no explicit actions or effects are supplied.
- Problems without explicit actions are now interpreted as binary
  conservation decisions, where each planning unit can be conserved or
  not conserved.
- Added an implicit conservation action and internally generated feature
  contributions based on the feature amounts stored in `dist_features`.
- The implicit conservation model uses `amount_after` to represent the
  feature amount obtained when a planning unit is conserved.
- Enabled target constraints and benefit objectives to work directly
  with the implicit conservation model.
- Added validation and clearer error messages for missing or zero
  feature contributions.
- Improved compatibility of implicit conservation problems with cost,
  benefit, fragmentation, and multi-objective workflows.

### Multi-objective run design and controls

- Revised the multi-objective run-design resolver used by weighted-sum,
  epsilon-constraint, and AUGMECON methods.
- Improved support for automatic and manually specified run designs
  through
  [`run_grid()`](https://josesalgr.github.io/multiscape/reference/run_grid.md)
  and
  [`run_manual()`](https://josesalgr.github.io/multiscape/reference/run_manual.md).
- Added and documented common multi-objective execution controls through
  [`mo_control()`](https://josesalgr.github.io/multiscape/reference/mo_control.md).
- Improved handling of infeasible runs, missing solutions, solver
  errors, and slack upper bounds.
- Standardized the storage of run-design parameters and objective values
  in the `SolutionSet` run table.
- Preserved infeasible runs in the run history while assigning
  `solution_id` only to runs that produced a stored solution.
- Improved objective evaluation and model preparation across
  multi-objective methods.
- Fixed weighted-sum objective preparation for implicit conservation
  benefit objectives.
- Improved validation of objective coefficient vectors and
  objective-specific error messages.

### Result extraction

- Added
  [`get_runs()`](https://josesalgr.github.io/multiscape/reference/get_runs.md)
  to extract run-level status, runtime, gap, design parameters, solution
  identifiers, and objective values.
- Added
  [`get_objectives()`](https://josesalgr.github.io/multiscape/reference/get_objectives.md)
  to extract objective values in long or wide format.
- Added
  [`get_objective_specs()`](https://josesalgr.github.io/multiscape/reference/get_objective_specs.md)
  to extract registered objective aliases, objective types, model types,
  optimization senses, and creation metadata.
- Updated objective extraction to include both `run_id` and
  `solution_id`.
- Updated existing extraction functions to work consistently with the
  unified `SolutionSet` architecture.
- Improved handling of infeasible runs and missing objective values
  during extraction.

### Solution-set management

- Added
  [`solution_filter()`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)
  to return a coherently filtered `SolutionSet`.
- [`solution_filter()`](https://josesalgr.github.io/multiscape/reference/solution_filter.md)
  can filter by `run_id`, `solution_id`, solver status, or feasibility.
- Added optional filtering of non-dominated solutions using `moocore`.
- Added support for selecting the objectives used to evaluate dominance.
- Ensured that filtering updates run tables, design tables, stored
  solutions, and summary tables consistently.
- Added cloning of `SolutionSet` objects before modification to prevent
  reference-based mutation of the original object.
- Added
  [`solution_append()`](https://josesalgr.github.io/multiscape/reference/solution_append.md)
  to combine compatible `SolutionSet` objects generated from the same
  planning problem.
- [`solution_append()`](https://josesalgr.github.io/multiscape/reference/solution_append.md)
  verifies compatibility of planning units, features, actions, effects,
  targets, constraints, locks, spatial relations, and objective
  definitions.
- Appended runs and solutions are automatically assigned unique `run_id`
  and `solution_id` values.
- Added support for combining solution sets obtained from different
  multi-objective methods or run designs applied to the same planning
  problem.
- Added
  [`solution_unique()`](https://josesalgr.github.io/multiscape/reference/solution_unique.md)
  to retain one representative from groups of equivalent solutions.
- [`solution_unique()`](https://josesalgr.github.io/multiscape/reference/solution_unique.md)
  can identify repeated solutions using either complete decision vectors
  or objective values.
- Added numerical tolerance controls for identifying equivalent points
  in objective space.
- Preserved runs without stored solutions when removing duplicated
  solutions.

### Frontier analysis

- Added
  [`frontier_extremes()`](https://josesalgr.github.io/multiscape/reference/frontier_extremes.md)
  to identify the observed minimum and maximum values of each objective.
- Added classification of observed bounds as `best` or `worst` according
  to each objective’s optimization sense.
- Added support for returning all tied extreme solutions or only the
  first representative.
- Added
  [`frontier_distances()`](https://josesalgr.github.io/multiscape/reference/frontier_distances.md)
  to calculate normalized distances to observed ideal and nadir points.
- Added automatic transformation of maximization objectives into a
  common minimization space for frontier calculations.
- Added range normalization so that objectives measured in different
  units contribute comparably to distance calculations.
- Added Euclidean, Manhattan, and Chebyshev distance metrics.
- Added rankings based on proximity to the observed ideal point and
  distance from the observed nadir point.
- Added original-scale ideal, nadir, and objective-range metadata to the
  returned distance tables.
- Clarified that frontier reference points are calculated from the
  solutions contained in the supplied `SolutionSet`.

### Selection analysis

- Added
  [`selection_frequency()`](https://josesalgr.github.io/multiscape/reference/selection_frequency.md)
  to calculate how frequently each planning-unit/action assignment is
  selected across stored solutions.
- Standardized selection analysis around a canonical
  planning-unit/action representation.
- Simple conservation-planning problems are represented using the
  implicit `conservation` action.
- Added
  [`selection_similarity()`](https://josesalgr.github.io/multiscape/reference/selection_similarity.md)
  to quantify structural similarity among solutions.
- Added Jaccard similarity for comparing selected planning-unit/action
  assignments.
- Added Hamming similarity for comparing complete binary assignment
  vectors, including shared non-selections.
- Added long-format and matrix-format similarity outputs.
- Added internal helpers to construct consistent long-format and
  matrix-format selection representations.
- Clarified the distinction between selection frequency and formal
  irreplaceability.

### Documentation and website

- Reorganized the pkgdown reference index into dedicated sections for:
  - result extraction;
  - solution-set management;
  - frontier analysis;
  - selection analysis;
  - multi-objective workflow configuration.
- Removed public documentation references to the internal `Solution`
  class.
- Updated function documentation to use the unified `SolutionSet`
  terminology.
- Updated examples and cross-references for `run_id`, `solution_id`,
  objective extraction, filtering, frontier analysis, and selection
  analysis.
- Added `moocore` as an optional dependency for non-dominance filtering.
- Updated GitHub Actions configurations for current Codecov and Node.js
  runner requirements.
- Updated Codecov uploads to use the PyPI CLI and avoid binary
  signature-verification failures.
- Updated GitHub Actions versions for Node.js 24 compatibility.

## multiscape 1.0.7

CRAN release: 2026-04-30

- Updated native routine registration to resolve additional CRAN
  LTO/gcc-ASAN checks.
- Revised examples and package metadata for CRAN compliance.

## multiscape 1.0.6

CRAN release: 2026-04-28

- Fix CRAN submission issues
- Revise examples and DESCRIPTION for CRAN resubmission

## multiscape 1.0.5

- Release candidate for CRAN.

## multiscape 1.0.4

- First CRAN release of `multiscape`.
- Provides a modular workflow for exact multi-objective spatial planning
  based on mixed-integer programming (MIP).
- Introduces the core `Problem`, `Solution`, and `SolutionSet` classes.
  The public result architecture was later unified around `SolutionSet`
  in version 1.1.0.
- Adds support for modular problem construction through
  [`create_problem()`](https://josesalgr.github.io/multiscape/reference/create_problem.md),
  `add_*()`, `set_*()`, and
  [`solve()`](https://josesalgr.github.io/multiscape/reference/solve.md).
- Supports atomic objective registration and multi-objective solution
  methods, including weighted-sum, epsilon-constraint, and AUGMECON.
- Includes support for spatial relations such as boundary, rook, queen,
  k-nearest neighbours, and distance-based relations.
- Supports commercial and open-source solvers, including Gurobi, CPLEX,
  CBC, and SYMPHONY.
- Adds user-facing extraction and visualization tools for planning
  units, actions, features, targets, spatial outputs, and trade-offs.
- Includes substantial updates to documentation, package structure, and
  contribution guidelines.

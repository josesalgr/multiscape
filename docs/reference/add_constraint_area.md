# Add area constraint

Add an area constraint to a planning problem.

This function stores one area-constraint specification in the `Problem`
object so that it can later be incorporated when the optimization model
is assembled. Area constraints can be imposed either on the total
selected planning-unit area or on the effective area of selected
actions.

Multiple area constraints can be added by calling this function
repeatedly, provided that no duplicated combination of action subset and
constraint sense is introduced.

## Usage

``` r
add_constraint_area(
  x,
  area,
  sense,
  tolerance = 0,
  area_col = NULL,
  area_unit = c("m2", "ha", "km2"),
  actions = NULL,
  name = NULL
)
```

## Arguments

- x:

  A `Problem` object.

- area:

  Numeric scalar greater than or equal to zero. Target value for the
  constrained area.

- sense:

  Character string indicating the type of area constraint. Must be one
  of `"min"`, `"max"`, or `"equal"`.

- tolerance:

  Numeric scalar greater than or equal to zero. Only used when
  `sense = "equal"`. In that case, equality is interpreted as a band
  around `area` with half-width `tolerance`. Ignored otherwise.

- area_col:

  Optional character string giving the name of the planning-unit area
  column. When `actions = NULL`, this column is used as the source of
  planning-unit areas. When `actions` is not `NULL`, the constraint uses
  `x$data$dist_actions$action_area`; `area_col` can still be used by the
  model builder as a fallback if action areas are missing and full
  planning-unit areas can be derived.

- area_unit:

  Character string indicating the unit of `area` and `tolerance`. Must
  be one of `"m2"`, `"ha"`, or `"km2"`.

- actions:

  Optional subset of actions to which the constraint applies. If `NULL`,
  the constraint applies to the total selected planning-unit area
  through the planning-unit selection variables. Otherwise, it applies
  to the effective area of the selected decision variables associated
  with the specified subset of actions, using
  `x$data$dist_actions$action_area`. This argument is resolved using the
  package's standard action subset parser.

- name:

  Optional character string used as the label of the stored linear
  constraint when it is later added to the optimization model. If
  `NULL`, a default name is generated.

## Value

An updated `Problem` object with the new area-constraint specification
appended to `x$data$constraints$area`.

## Details

Use this function when area requirements must be imposed either on the
total selected landscape or on the effective area allocated to specific
actions.

**Total selected area.**

Let \\\mathcal{I}\\ denote the set of planning units and let \\a_i \ge
0\\ be the area associated with planning unit \\i \in \mathcal{I}\\.

When `actions = NULL`, the constraint refers to the total selected area
in the problem. In that case, let \\w_i \in \\0,1\\\\ denote the binary
variable indicating whether planning unit \\i\\ is selected by at least
one decision in the model.

Depending on `sense`, this function stores one of the following
constraints.

If `sense = "min"`: \$\$ \sum\_{i \in \mathcal{I}} a_i w_i \ge A \$\$

If `sense = "max"`: \$\$ \sum\_{i \in \mathcal{I}} a_i w_i \le A \$\$

If `sense = "equal"` and `tolerance = 0`: \$\$ \sum\_{i \in \mathcal{I}}
a_i w_i = A \$\$

If `sense = "equal"` and `tolerance > 0`, the equality is stored as a
two-sided band: \$\$ A - \tau \le \sum\_{i \in \mathcal{I}} a_i w_i \le
A + \tau \$\$ where \\\tau\\ is the value supplied through `tolerance`.

**Action-specific effective area.**

When `actions` is not `NULL`, the constraint refers to the effective
area of the selected decisions associated with the specified subset of
actions.

Let \\\mathcal{A}^\star \subseteq \mathcal{A}\\ denote the specified
action subset and let \\x\_{ia} \in \\0,1\\\\ denote the binary variable
indicating whether action \\a \in \mathcal{A}^\star\\ is selected in
planning unit \\i \in \mathcal{I}\\. Let \\b\_{ia} \ge 0\\ denote the
effective action area associated with feasible pair \\(i,a)\\, as stored
in `x$data$dist_actions$action_area`. In that case, the constrained
quantity is: \$\$ \sum\_{i \in \mathcal{I}} \sum\_{a \in
\mathcal{A}^\star} b\_{ia} x\_{ia}. \$\$

Effective action areas are defined in
[`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md).
They can be supplied manually through the `action_area` argument,
derived from spatial `include_pairs`, or default to full planning-unit
areas when these can be derived from the problem.

Consequently, if no partial action areas are supplied and each feasible
action is assumed to apply to the full planning unit, then an
action-specific area constraint is numerically equivalent to using
planning-unit areas for those action decisions. If partial action areas
are supplied, the constraint uses those effective areas instead.

**Area units and area sources.**

The value of `area_unit` indicates the unit in which `area` and
`tolerance` are expressed.

When `actions = NULL`, areas are obtained from the planning-unit table
or planning-unit geometry. If `area_col` is provided, that column is
used. Otherwise, the model builder determines the default area source
according to the internal rules of the package.

When `actions` is not `NULL`, the model builder uses
`x$data$dist_actions$action_area`. These values are stored internally in
square metres and are converted to `area_unit` when the model is built.
If action areas are missing for relevant feasible `(pu, action)` pairs,
the model builder may use `area_col` as a fallback to derive full
planning-unit areas. If valid action areas still cannot be obtained,
model construction fails with an error.

This function only stores the constraint specification; it does not
validate the feasibility of the threshold against the available planning
units or actions at this stage.

Multiple area constraints can be stored in a `Problem` object. However,
at most one can be stored for the same combination of action subset and
constraint sense. Attempting to add a duplicated `actions`–`sense`
combination results in an error.

## See also

[`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md),
[`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md)

## Examples

``` r
pu <- data.frame(
  id = 1:4,
  cost = c(2, 3, 1, 4),
  area_ha = c(10, 15, 8, 20)
)

features <- data.frame(
  id = 1:2,
  name = c("sp1", "sp2")
)

dist_features <- data.frame(
  pu = c(1, 1, 2, 3, 4, 4),
  feature = c(1, 2, 1, 2, 1, 2),
  amount = c(1, 2, 1, 3, 2, 1)
)

actions <- data.frame(
  id = c("conservation", "restoration")
)

p <- create_problem(
  pu = pu,
  features = features,
  dist_features = dist_features
)

p <- add_actions(
  p,
  actions = actions,
  cost = c(conservation = 1, restoration = 2)
)

# Constrain the total selected planning-unit area.
p <- add_constraint_area(
  x = p,
  area = 25,
  sense = "min",
  area_col = "area_ha",
  area_unit = "ha"
)

# Constrain the effective area allocated to restoration.
# Because add_actions() can derive full planning-unit areas here,
# restoration action areas default to the full area of each feasible PU.
p <- add_constraint_area(
  x = p,
  area = 15,
  sense = "max",
  area_col = "area_ha",
  area_unit = "ha",
  actions = "restoration"
)

p$data$constraints$area
#>   type sense value tolerance unit area_col     actions                 name
#> 1 area   min    25         0   ha  area_ha        <NA>             area_min
#> 2 area   max    15         0   ha  area_ha restoration area_max_restoration
```

# Add action effects to a planning problem

Define the effects of management actions on features across planning
units.

Effects are stored in a canonical representation in an effects table,
with one row per `(pu, action, feature)` triple and three main effect
columns:

- `amount_after`: the feature amount expected after applying the action,

- `benefit`: the positive component of the net change,

- `loss`: the magnitude of the negative component of the net change.

Let \\i\\ index planning units, \\a\\ index actions, and \\f\\ index
features. Let \\b\_{if}\\ denote the baseline amount of feature \\f\\ in
planning unit \\i\\, and let \\\Delta\_{iaf}\\ denote the net effect of
applying action \\a\\. The after-action amount is: \$\$
\mathrm{amount\\after}\_{iaf} = b\_{if} + \Delta\_{iaf}. \$\$

Under the semantics adopted by this package, each
`(pu, action, feature)` triple represents a single net effect.
Consequently, after validation and aggregation, a stored row cannot have
both `benefit > 0` and `loss > 0` at the same time.

## Usage

``` r
add_effects(
  x,
  effects = NULL,
  effect_type = c("delta", "after"),
  effect_aggregation = c("sum", "mean"),
  component = c("any", "benefit", "loss")
)
```

## Arguments

- x:

  A `Problem` object created with
  [`create_problem`](https://josesalgr.github.io/multiscape/reference/create_problem.md).
  It must already contain feasible actions; run
  [`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md)
  first.

- effects:

  Effect specification. One of:

  - `NULL`, to store an empty effects table,

  - a `data.frame(action, feature, multiplier)`,

  - a `data.frame(pu, action, feature, ...)` with explicit effects,

  - a named list of
    [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
    objects, one per action.

- effect_type:

  Character string indicating how supplied effect values are
  interpreted. Must be one of:

  - `"delta"`: values represent signed net changes,

  - `"after"`: values represent after-action amounts and are converted
    to net changes relative to baseline feature amounts.

- effect_aggregation:

  Character string giving the aggregation used when converting raster
  values to planning-unit level. Must be one of `"sum"` or `"mean"`.

- component:

  Character string controlling which component of the canonical effects
  table is retained. Must be one of:

  - `"any"`: keep all stored effect rows,

  - `"benefit"`: keep only rows with `benefit > 0`,

  - `"loss"`: keep only rows with `loss > 0`.

## Value

An updated `Problem` object containing:

- `dist_effects`:

  A canonical effects table with columns `pu`, `action`, `feature`,
  `amount_after`, `benefit`, `loss`, `internal_pu`, `internal_action`,
  `internal_feature`, and optional labels such as `feature_name` and
  `action_name`.

- `effects_meta`:

  Metadata describing how effects were interpreted and stored.

## Details

**When to use `add_effects()`.**

Use this function when you want to specify what feasible actions do to
features. It is the stage at which an action-based decision space is
linked to feature-level ecological or functional consequences.

This function provides a unified interface for specifying action effects
from several input formats while enforcing a single internal
representation. Regardless of how the user supplies the effects, the
stored output always follows the same canonical structure based on
`amount_after` and non-negative `benefit`/`loss` components.

Let \\i \in \mathcal{I}\\ index planning units, \\a \in \mathcal{A}\\
index actions, and \\f \in \mathcal{F}\\ index features. Let \\b\_{if}\\
denote the baseline amount of feature \\f\\ in planning unit \\i\\, as
given by the feature-distribution table. Let \\\Delta\_{iaf}\\ denote
the net change caused by applying action \\a\\ in planning unit \\i\\ to
feature \\f\\. The canonical stored representation is:

\$\$ \mathrm{amount\\after}\_{iaf} = b\_{if} + \Delta\_{iaf}, \$\$

\$\$ \mathrm{benefit}\_{iaf} = \max(\Delta\_{iaf}, 0), \$\$

\$\$ \mathrm{loss}\_{iaf} = \max(-\Delta\_{iaf}, 0). \$\$

Hence:

- if \\\Delta\_{iaf} \> 0\\, then `benefit > 0` and `loss = 0`,

- if \\\Delta\_{iaf} \< 0\\, then `benefit = 0` and `loss > 0`,

- if \\\Delta\_{iaf} = 0\\, then both are zero and `amount_after` equals
  the baseline amount.

Thus, `benefit` and `loss` describe the net change relative to the
baseline, whereas `amount_after` describes the final feature amount
under the action. This distinction is important for actions that
maintain baseline values. For example, if an action preserves a feature
unchanged, then `benefit = 0`, `loss = 0`, and `amount_after` equals the
baseline amount.

**Why split effects into benefit and loss?**

This representation avoids ambiguity in downstream optimization models.
It allows the package to support, for example, objectives that maximize
beneficial effects, minimize damages, impose no-net-loss conditions, or
combine both components differently in multi-objective formulations.

**Supported effect specifications**

The `effects` argument may be provided in one of the following forms:

1.  `NULL`. An empty effects table is stored.

2.  A `data.frame(action, feature, multiplier)`. In this case, effects
    are constructed by multiplying baseline feature amounts by the
    supplied multiplier. The interpretation depends on `effect_type`.

    If `effect_type = "delta"`, the multiplier represents a relative net
    change: \$\$ \Delta\_{iaf} = b\_{if} \times m\_{af}. \$\$

    If `effect_type = "after"`, the multiplier represents the
    after-action amount relative to the baseline: \$\$
    \mathrm{amount\\after}\_{iaf} = b\_{if} \times m\_{af}, \$\$ and the
    net effect is: \$\$ \Delta\_{iaf} = \mathrm{amount\\after}\_{iaf} -
    b\_{if} = b\_{if}(m\_{af} - 1). \$\$

    Thus, under `effect_type = "after"`, a multiplier of `1` means no
    change, a multiplier below `1` means a loss, and a multiplier above
    `1` means a gain. This specification is expanded over all feasible
    `(pu, action)` pairs.

3.  A `data.frame(pu, action, feature, ...)` giving explicit effects for
    individual triples. The table may contain:

    - `delta` or `effect`: interpreted as signed net changes,

    - `after`: interpreted as after-action amounts and requiring
      `effect_type = "after"`,

    - `benefit` and/or `loss`: explicit non-negative split components,

    - legacy signed `benefit` without `loss`: interpreted as a signed
      net effect for backwards compatibility.

4.  A named list of
    [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
    objects, one per action. In this case, names must match action ids,
    and each raster must contain one layer per feature. Raster values
    are aggregated to planning-unit level using `effect_aggregation`.

**Interpretation of `effect_type`**

If `effect_type = "delta"`, supplied values are interpreted as net
changes directly. For explicit `delta` or `effect` columns, values are
used as signed changes. For `multiplier` inputs, values are interpreted
as relative net changes:

\$\$ \Delta\_{iaf} = b\_{if} \times m\_{af}. \$\$

If `effect_type = "after"`, supplied values are interpreted as
after-action amounts and converted internally to net effects using:

\$\$ \Delta\_{iaf} = \mathrm{after}\_{iaf} - b\_{if}. \$\$

For `multiplier` inputs under `effect_type = "after"`, the after-action
amount is computed as \\b\_{if} \times m\_{af}\\, so that:

\$\$ \Delta\_{iaf} = b\_{if}(m\_{af} - 1). \$\$

Missing baseline values are treated as zero.

**Feasibility and locked-out decisions**

Effects are only retained for feasible `(pu, action)` pairs. Thus,
[`add_actions()`](https://josesalgr.github.io/multiscape/reference/add_actions.md)
must be called first. Pairs marked as locked out (`status == 3`) are
removed before storing the final effects table.

This function does not define the action-decision layer itself; it
builds on the feasible `(pu, action)` pairs already stored in the
problem.

**Duplicate rows and semantic validation**

If multiple rows are supplied for the same `(pu, action, feature)`
triple, they are aggregated by summing `benefit` and `loss` separately.
The resulting triple must still respect the package semantics, namely
that both components cannot be strictly positive simultaneously. Inputs
violating this rule are rejected.

**Component filtering**

After canonicalization and validation, rows can be restricted to:

- `component = "any"`: keep all stored effect rows, including neutral
  effects,

- `component = "benefit"`: keep only rows with `benefit > 0`,

- `component = "loss"`: keep only rows with `loss > 0`.

Zero-effect rows are retained by default because they may encode valid
neutral effects. They are removed only when using
`component = "benefit"` or `component = "loss"`.

**Raster handling**

When effects are supplied as rasters, they are automatically aligned to
the planning-unit raster or geometry when needed before extraction or
zonal aggregation.

**Stored output**

The resulting effects table contains user-facing ids, internal integer
ids, and optional labels for actions and features. Metadata describing
the stored representation and input interpretation are written to an
effects metadata field.

After defining effects, typical next steps include adding objectives
that use beneficial or harmful effects, and then solving the configured
problem.

## See also

[`add_actions`](https://josesalgr.github.io/multiscape/reference/add_actions.md),
[`add_benefits`](https://josesalgr.github.io/multiscape/reference/add_benefits.md),
[`add_losses`](https://josesalgr.github.io/multiscape/reference/add_losses.md)

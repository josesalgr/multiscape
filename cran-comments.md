## R CMD check results

0 errors | 0 warnings | 3 notes

## Update

This update to version 1.4.1 adds signed-effect objectives, complete
example-data loaders, and revised documentation and examples.

The deprecated `add_objective_max_benefit()` now delegates to the signed
`add_objective_max_effect()`. The deprecated `add_objective_min_loss()`
retains its original criterion. These changes are documented in NEWS.md.

## CRAN check notes

### 1. checking package dependencies ... NOTE

Packages suggested but not available for checking:
`Rsymphony`, `Rcplex`, `slam`, `gurobi`

These packages are listed in `Suggests` because they provide optional solver-specific functionality and are used conditionally.

The `Description` field explicitly states how non-mainstream suggested packages can be obtained:
- `'gurobi'` is distributed with the Gurobi Optimizer installation;
- `'rcbc'` is available from GitHub at <https://github.com/dirkschumacher/rcbc>.

### 2. checking installed package size ... NOTE

Installed size is 9.7Mb, mainly due to example data, documentation,
R code and the compiled library. Unused files have been removed and
the vignette cache has been reduced without changing its results.

### 3. checking for future file timestamps ... NOTE

This NOTE was observed in a local Windows check and appears to be environment-specific.

## Test environments

* local Windows 10 x64, R 4.4.1
* GitHub Actions:
  * ubuntu-latest (oldrel-1, release, devel)
  * windows-latest (release)
  * macos-latest (release)

## Downstream dependencies

There are no reverse dependencies.

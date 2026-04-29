## R CMD check results

0 errors | 0 warnings | 3 notes

## Resubmission

This is a resubmission to address the additional LTO/gcc-ASAN issue reported by CRAN.

The native routine registration in src/init.c was updated for
_multiscape_rcpp_prepare_objective_min_intervention_impact. The registered
number of arguments and the external declaration now match the Rcpp-generated
wrapper in src/RcppExports.cpp.

The package was previously accepted on CRAN as version 1.0.6. This update
addresses the additional issues reported for that CRAN version.

## CRAN check notes

### 1. checking package dependencies ... NOTE

Packages suggested but not available for checking:
`Rsymphony`, `Rcplex`, `slam`, `gurobi`

These packages are listed in `Suggests` because they provide optional solver-specific functionality and are used conditionally.

The `Description` field explicitly states how non-mainstream suggested packages can be obtained:
- `'gurobi'` is distributed with the Gurobi Optimizer installation;
- `'rcbc'` is available from GitHub at <https://github.com/dirkschumacher/rcbc>.

### 2. checking installed package size ... NOTE

Installed size is 9.0Mb, mainly due to example data, documentation, and compiled code.

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

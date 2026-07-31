# Add spatial boundary-length relations

Build and register a boundary-length spatial relation between planning
units.

Boundary relations represent shared edge length between adjacent
polygons. In contrast to queen adjacency, they only account for boundary
segments of positive length and ignore point-only contacts.

## Usage

``` r
add_spatial_boundary(
  x,
  boundary = NULL,
  geometry = NULL,
  name = "boundary",
  weight_col = NULL,
  weight_multiplier = 1,
  include_self = TRUE,
  edge_factor = 1
)
```

## Arguments

- x:

  A `Problem` object.

- boundary:

  Optional `data.frame` describing boundary lengths. Accepted formats
  are:

  - `(id1, id2, boundary)`, or

  - `(pu1, pu2, weight)`.

- geometry:

  Optional `sf` object with planning-unit polygons and an `id` column.
  If `NULL`, `x$data$pu_sf` is used.

- name:

  Character string giving the key under which the relation is stored.

- weight_col:

  Optional character string giving the name of the weight column in
  `boundary`. If `NULL`, the function tries to infer it from
  `"boundary"` or `"weight"`.

- weight_multiplier:

  Positive numeric scalar applied to all boundary weights.

- include_self:

  Logical. If `TRUE`, include diagonal entries representing exposed
  boundary.

- edge_factor:

  Numeric scalar greater than or equal to zero. Multiplier applied to
  exposed boundary when constructing diagonal entries.

## Value

An updated `Problem` object with the stored relation in
`x$data$spatial_relations[[name]]`.

## Details

Use this function when spatial structure should be represented through
shared boundary length rather than binary contiguity or coordinate-based
proximity.

Two input modes are supported:

1.  **Boundary-table mode.** If `boundary` is supplied, it is
    interpreted as a boundary table, for example a Marxan-style
    `bound.dat`.

2.  **Geometry mode.** If `boundary = NULL`, boundary lengths are
    derived from polygon geometry using `geometry` or `x$data$pu_sf`.

Let \\\omega\_{ij} \ge 0\\ denote the shared boundary length between
planning units \\i\\ and \\j\\, multiplied by `weight_multiplier`.

For off-diagonal entries \\i \neq j\\, the stored weight is: \$\$
\omega\_{ij} = \mathrm{\gamma} \times b\_{ij}, \$\$ where \\b\_{ij}\\ is
the shared boundary length and \\\gamma\\ is the user-supplied
`weight_multiplier`.

If `include_self = TRUE`, diagonal entries are also created. These are
not geometric self-neighbours in the graph sense; instead, they
represent the effective boundary exposed to the outside of the solution.

Let \\p_i\\ be the total perimeter of planning unit \\i\\, and let
\\\sum\_{j \neq i} \omega\_{ij}\\ be the total incident shared boundary
recorded for that planning unit. Then the exposed boundary is
represented by a diagonal term derived from the difference between total
perimeter and shared boundary, scaled by `edge_factor`.

These diagonal terms are useful in boundary-based compactness or
fragmentation objectives, because they encode the portion of each
planning unit's perimeter that would remain exposed if the unit were
selected.

**Boundary-table mode**

If `boundary` is provided, accepted formats are:

- `(id1, id2, boundary)`, or

- `(pu1, pu2, weight)`.

If the table contains diagonal rows \\(i,i)\\, these are interpreted as
total perimeter values in boundary-table mode.

**Geometry mode**

If `boundary = NULL`, shared boundary lengths are derived directly from
polygon geometry. Only positive-length intersections are retained. Point
touches are ignored.

**Storage**

The final relation is stored through
[`add_spatial_relations`](https://josesalgr.github.io/multiscape/reference/add_spatial_relations.md),
typically as an undirected relation with optional diagonal entries.

## See also

[`add_spatial_relations`](https://josesalgr.github.io/multiscape/reference/add_spatial_relations.md),
[`add_objective_min_fragmentation_pu`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_pu.md),
[`add_objective_min_fragmentation_action`](https://josesalgr.github.io/multiscape/reference/add_objective_min_fragmentation_action.md)

## Examples

``` r
# Load a complete simulated planning problem.
example_data <- load_sim_multiaction()

p <- create_problem(
  pu = example_data$planning_units,
  features = example_data$features,
  dist_features = example_data$dist_features,
  cost = "cost"
)

p <- add_spatial_boundary(
  x = p,
  name = "boundary",
  include_self = TRUE,
  edge_factor = 1
)

p$data$spatial_relations$boundary
#>     internal_pu1 internal_pu2 weight pu1 pu2                     source
#> 18            10           11      1  10  11  boundary_sf_shared_length
#> 19            10           18      1  10  18  boundary_sf_shared_length
#> 20            11           12      1  11  12  boundary_sf_shared_length
#> 21            11           19      1  11  19  boundary_sf_shared_length
#> 22            12           13      1  12  13  boundary_sf_shared_length
#> 23            12           20      1  12  20  boundary_sf_shared_length
#> 24            13           14      1  13  14  boundary_sf_shared_length
#> 25            13           21      1  13  21  boundary_sf_shared_length
#> 26            14           15      1  14  15  boundary_sf_shared_length
#> 27            14           22      1  14  22  boundary_sf_shared_length
#> 28            15           16      1  15  16  boundary_sf_shared_length
#> 29            15           23      1  15  23  boundary_sf_shared_length
#> 30            16           24      1  16  24  boundary_sf_shared_length
#> 31            17           18      1  17  18  boundary_sf_shared_length
#> 32            17           25      1  17  25  boundary_sf_shared_length
#> 33            18           19      1  18  19  boundary_sf_shared_length
#> 34            18           26      1  18  26  boundary_sf_shared_length
#> 35            19           20      1  19  20  boundary_sf_shared_length
#> 36            19           27      1  19  27  boundary_sf_shared_length
#> 1              1            2      1   1   2  boundary_sf_shared_length
#> 2              1            9      1   1   9  boundary_sf_shared_length
#> 37            20           21      1  20  21  boundary_sf_shared_length
#> 38            20           28      1  20  28  boundary_sf_shared_length
#> 39            21           22      1  21  22  boundary_sf_shared_length
#> 40            21           29      1  21  29  boundary_sf_shared_length
#> 41            22           23      1  22  23  boundary_sf_shared_length
#> 42            22           30      1  22  30  boundary_sf_shared_length
#> 43            23           24      1  23  24  boundary_sf_shared_length
#> 44            23           31      1  23  31  boundary_sf_shared_length
#> 45            24           32      1  24  32  boundary_sf_shared_length
#> 46            25           26      1  25  26  boundary_sf_shared_length
#> 47            25           33      1  25  33  boundary_sf_shared_length
#> 48            26           27      1  26  27  boundary_sf_shared_length
#> 49            26           34      1  26  34  boundary_sf_shared_length
#> 50            27           28      1  27  28  boundary_sf_shared_length
#> 51            27           35      1  27  35  boundary_sf_shared_length
#> 52            28           29      1  28  29  boundary_sf_shared_length
#> 53            28           36      1  28  36  boundary_sf_shared_length
#> 54            29           30      1  29  30  boundary_sf_shared_length
#> 55            29           37      1  29  37  boundary_sf_shared_length
#> 4              2           10      1   2  10  boundary_sf_shared_length
#> 3              2            3      1   2   3  boundary_sf_shared_length
#> 56            30           31      1  30  31  boundary_sf_shared_length
#> 57            30           38      1  30  38  boundary_sf_shared_length
#> 58            31           32      1  31  32  boundary_sf_shared_length
#> 59            31           39      1  31  39  boundary_sf_shared_length
#> 60            32           40      1  32  40  boundary_sf_shared_length
#> 61            33           34      1  33  34  boundary_sf_shared_length
#> 62            33           41      1  33  41  boundary_sf_shared_length
#> 63            34           35      1  34  35  boundary_sf_shared_length
#> 64            34           42      1  34  42  boundary_sf_shared_length
#> 65            35           36      1  35  36  boundary_sf_shared_length
#> 66            35           43      1  35  43  boundary_sf_shared_length
#> 67            36           37      1  36  37  boundary_sf_shared_length
#> 68            36           44      1  36  44  boundary_sf_shared_length
#> 69            37           38      1  37  38  boundary_sf_shared_length
#> 70            37           45      1  37  45  boundary_sf_shared_length
#> 71            38           39      1  38  39  boundary_sf_shared_length
#> 72            38           46      1  38  46  boundary_sf_shared_length
#> 73            39           40      1  39  40  boundary_sf_shared_length
#> 74            39           47      1  39  47  boundary_sf_shared_length
#> 6              3           11      1   3  11  boundary_sf_shared_length
#> 5              3            4      1   3   4  boundary_sf_shared_length
#> 75            40           48      1  40  48  boundary_sf_shared_length
#> 76            41           42      1  41  42  boundary_sf_shared_length
#> 77            41           49      1  41  49  boundary_sf_shared_length
#> 78            42           43      1  42  43  boundary_sf_shared_length
#> 79            42           50      1  42  50  boundary_sf_shared_length
#> 80            43           44      1  43  44  boundary_sf_shared_length
#> 81            43           51      1  43  51  boundary_sf_shared_length
#> 82            44           45      1  44  45  boundary_sf_shared_length
#> 83            44           52      1  44  52  boundary_sf_shared_length
#> 84            45           46      1  45  46  boundary_sf_shared_length
#> 85            45           53      1  45  53  boundary_sf_shared_length
#> 86            46           47      1  46  47  boundary_sf_shared_length
#> 87            46           54      1  46  54  boundary_sf_shared_length
#> 88            47           48      1  47  48  boundary_sf_shared_length
#> 89            47           55      1  47  55  boundary_sf_shared_length
#> 90            48           56      1  48  56  boundary_sf_shared_length
#> 91            49           50      1  49  50  boundary_sf_shared_length
#> 92            49           57      1  49  57  boundary_sf_shared_length
#> 8              4           12      1   4  12  boundary_sf_shared_length
#> 7              4            5      1   4   5  boundary_sf_shared_length
#> 93            50           51      1  50  51  boundary_sf_shared_length
#> 94            50           58      1  50  58  boundary_sf_shared_length
#> 95            51           52      1  51  52  boundary_sf_shared_length
#> 96            51           59      1  51  59  boundary_sf_shared_length
#> 97            52           53      1  52  53  boundary_sf_shared_length
#> 98            52           60      1  52  60  boundary_sf_shared_length
#> 99            53           54      1  53  54  boundary_sf_shared_length
#> 100           53           61      1  53  61  boundary_sf_shared_length
#> 101           54           55      1  54  55  boundary_sf_shared_length
#> 102           54           62      1  54  62  boundary_sf_shared_length
#> 103           55           56      1  55  56  boundary_sf_shared_length
#> 104           55           63      1  55  63  boundary_sf_shared_length
#> 105           56           64      1  56  64  boundary_sf_shared_length
#> 106           57           58      1  57  58  boundary_sf_shared_length
#> 107           58           59      1  58  59  boundary_sf_shared_length
#> 108           59           60      1  59  60  boundary_sf_shared_length
#> 10             5           13      1   5  13  boundary_sf_shared_length
#> 9              5            6      1   5   6  boundary_sf_shared_length
#> 109           60           61      1  60  61  boundary_sf_shared_length
#> 110           61           62      1  61  62  boundary_sf_shared_length
#> 111           62           63      1  62  63  boundary_sf_shared_length
#> 112           63           64      1  63  64  boundary_sf_shared_length
#> 12             6           14      1   6  14  boundary_sf_shared_length
#> 11             6            7      1   6   7  boundary_sf_shared_length
#> 14             7           15      1   7  15  boundary_sf_shared_length
#> 13             7            8      1   7   8  boundary_sf_shared_length
#> 15             8           16      1   8  16  boundary_sf_shared_length
#> 16             9           10      1   9  10  boundary_sf_shared_length
#> 17             9           17      1   9  17  boundary_sf_shared_length
#> 113            1            1      2   1   1 boundary_sf_diag_effective
#> 122           10           10      0  10  10 boundary_sf_diag_effective
#> 123           11           11      0  11  11 boundary_sf_diag_effective
#> 124           12           12      0  12  12 boundary_sf_diag_effective
#> 125           13           13      0  13  13 boundary_sf_diag_effective
#> 126           14           14      0  14  14 boundary_sf_diag_effective
#> 127           15           15      0  15  15 boundary_sf_diag_effective
#> 128           16           16      1  16  16 boundary_sf_diag_effective
#> 129           17           17      1  17  17 boundary_sf_diag_effective
#> 130           18           18      0  18  18 boundary_sf_diag_effective
#> 131           19           19      0  19  19 boundary_sf_diag_effective
#> 114            2            2      1   2   2 boundary_sf_diag_effective
#> 132           20           20      0  20  20 boundary_sf_diag_effective
#> 133           21           21      0  21  21 boundary_sf_diag_effective
#> 134           22           22      0  22  22 boundary_sf_diag_effective
#> 135           23           23      0  23  23 boundary_sf_diag_effective
#> 136           24           24      1  24  24 boundary_sf_diag_effective
#> 137           25           25      1  25  25 boundary_sf_diag_effective
#> 138           26           26      0  26  26 boundary_sf_diag_effective
#> 139           27           27      0  27  27 boundary_sf_diag_effective
#> 140           28           28      0  28  28 boundary_sf_diag_effective
#> 141           29           29      0  29  29 boundary_sf_diag_effective
#> 115            3            3      1   3   3 boundary_sf_diag_effective
#> 142           30           30      0  30  30 boundary_sf_diag_effective
#> 143           31           31      0  31  31 boundary_sf_diag_effective
#> 144           32           32      1  32  32 boundary_sf_diag_effective
#> 145           33           33      1  33  33 boundary_sf_diag_effective
#> 146           34           34      0  34  34 boundary_sf_diag_effective
#> 147           35           35      0  35  35 boundary_sf_diag_effective
#> 148           36           36      0  36  36 boundary_sf_diag_effective
#> 149           37           37      0  37  37 boundary_sf_diag_effective
#> 150           38           38      0  38  38 boundary_sf_diag_effective
#> 151           39           39      0  39  39 boundary_sf_diag_effective
#> 116            4            4      1   4   4 boundary_sf_diag_effective
#> 152           40           40      1  40  40 boundary_sf_diag_effective
#> 153           41           41      1  41  41 boundary_sf_diag_effective
#> 154           42           42      0  42  42 boundary_sf_diag_effective
#> 155           43           43      0  43  43 boundary_sf_diag_effective
#> 156           44           44      0  44  44 boundary_sf_diag_effective
#> 157           45           45      0  45  45 boundary_sf_diag_effective
#> 158           46           46      0  46  46 boundary_sf_diag_effective
#> 159           47           47      0  47  47 boundary_sf_diag_effective
#> 160           48           48      1  48  48 boundary_sf_diag_effective
#> 161           49           49      1  49  49 boundary_sf_diag_effective
#> 117            5            5      1   5   5 boundary_sf_diag_effective
#> 162           50           50      0  50  50 boundary_sf_diag_effective
#> 163           51           51      0  51  51 boundary_sf_diag_effective
#> 164           52           52      0  52  52 boundary_sf_diag_effective
#> 165           53           53      0  53  53 boundary_sf_diag_effective
#> 166           54           54      0  54  54 boundary_sf_diag_effective
#> 167           55           55      0  55  55 boundary_sf_diag_effective
#> 168           56           56      1  56  56 boundary_sf_diag_effective
#> 169           57           57      2  57  57 boundary_sf_diag_effective
#> 170           58           58      1  58  58 boundary_sf_diag_effective
#> 171           59           59      1  59  59 boundary_sf_diag_effective
#> 118            6            6      1   6   6 boundary_sf_diag_effective
#> 172           60           60      1  60  60 boundary_sf_diag_effective
#> 173           61           61      1  61  61 boundary_sf_diag_effective
#> 174           62           62      1  62  62 boundary_sf_diag_effective
#> 175           63           63      1  63  63 boundary_sf_diag_effective
#> 176           64           64      2  64  64 boundary_sf_diag_effective
#> 119            7            7      1   7   7 boundary_sf_diag_effective
#> 120            8            8      2   8   8 boundary_sf_diag_effective
#> 121            9            9      1   9   9 boundary_sf_diag_effective
#>     relation_name
#> 18       boundary
#> 19       boundary
#> 20       boundary
#> 21       boundary
#> 22       boundary
#> 23       boundary
#> 24       boundary
#> 25       boundary
#> 26       boundary
#> 27       boundary
#> 28       boundary
#> 29       boundary
#> 30       boundary
#> 31       boundary
#> 32       boundary
#> 33       boundary
#> 34       boundary
#> 35       boundary
#> 36       boundary
#> 1        boundary
#> 2        boundary
#> 37       boundary
#> 38       boundary
#> 39       boundary
#> 40       boundary
#> 41       boundary
#> 42       boundary
#> 43       boundary
#> 44       boundary
#> 45       boundary
#> 46       boundary
#> 47       boundary
#> 48       boundary
#> 49       boundary
#> 50       boundary
#> 51       boundary
#> 52       boundary
#> 53       boundary
#> 54       boundary
#> 55       boundary
#> 4        boundary
#> 3        boundary
#> 56       boundary
#> 57       boundary
#> 58       boundary
#> 59       boundary
#> 60       boundary
#> 61       boundary
#> 62       boundary
#> 63       boundary
#> 64       boundary
#> 65       boundary
#> 66       boundary
#> 67       boundary
#> 68       boundary
#> 69       boundary
#> 70       boundary
#> 71       boundary
#> 72       boundary
#> 73       boundary
#> 74       boundary
#> 6        boundary
#> 5        boundary
#> 75       boundary
#> 76       boundary
#> 77       boundary
#> 78       boundary
#> 79       boundary
#> 80       boundary
#> 81       boundary
#> 82       boundary
#> 83       boundary
#> 84       boundary
#> 85       boundary
#> 86       boundary
#> 87       boundary
#> 88       boundary
#> 89       boundary
#> 90       boundary
#> 91       boundary
#> 92       boundary
#> 8        boundary
#> 7        boundary
#> 93       boundary
#> 94       boundary
#> 95       boundary
#> 96       boundary
#> 97       boundary
#> 98       boundary
#> 99       boundary
#> 100      boundary
#> 101      boundary
#> 102      boundary
#> 103      boundary
#> 104      boundary
#> 105      boundary
#> 106      boundary
#> 107      boundary
#> 108      boundary
#> 10       boundary
#> 9        boundary
#> 109      boundary
#> 110      boundary
#> 111      boundary
#> 112      boundary
#> 12       boundary
#> 11       boundary
#> 14       boundary
#> 13       boundary
#> 15       boundary
#> 16       boundary
#> 17       boundary
#> 113      boundary
#> 122      boundary
#> 123      boundary
#> 124      boundary
#> 125      boundary
#> 126      boundary
#> 127      boundary
#> 128      boundary
#> 129      boundary
#> 130      boundary
#> 131      boundary
#> 114      boundary
#> 132      boundary
#> 133      boundary
#> 134      boundary
#> 135      boundary
#> 136      boundary
#> 137      boundary
#> 138      boundary
#> 139      boundary
#> 140      boundary
#> 141      boundary
#> 115      boundary
#> 142      boundary
#> 143      boundary
#> 144      boundary
#> 145      boundary
#> 146      boundary
#> 147      boundary
#> 148      boundary
#> 149      boundary
#> 150      boundary
#> 151      boundary
#> 116      boundary
#> 152      boundary
#> 153      boundary
#> 154      boundary
#> 155      boundary
#> 156      boundary
#> 157      boundary
#> 158      boundary
#> 159      boundary
#> 160      boundary
#> 161      boundary
#> 117      boundary
#> 162      boundary
#> 163      boundary
#> 164      boundary
#> 165      boundary
#> 166      boundary
#> 167      boundary
#> 168      boundary
#> 169      boundary
#> 170      boundary
#> 171      boundary
#> 118      boundary
#> 172      boundary
#> 173      boundary
#> 174      boundary
#> 175      boundary
#> 176      boundary
#> 119      boundary
#> 120      boundary
#> 121      boundary
```

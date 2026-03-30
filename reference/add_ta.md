# Add a generic indicator or comparison series

Add a generic indicator or comparison series

## Usage

``` r
add_ta(
  chart,
  values,
  type = c("line", "area", "histogram"),
  pane = "price",
  name = NULL,
  color = "#2563eb",
  pane_height = NULL,
  overlay = identical(pane, "price")
)
```

## Arguments

- chart:

  A `lightweightchartR` chart object.

- values:

  An `xts`, `zoo`, or data frame object with a `time` column.

- type:

  One of `"line"`, `"area"`, or `"histogram"`.

- pane:

  Target pane. Defaults to `"price"`.

- name:

  Optional display name.

- color:

  Optional series color.

- pane_height:

  Relative pane height for new panes.

- overlay:

  Whether to overlay on the existing price scale.

## Value

The updated chart object.

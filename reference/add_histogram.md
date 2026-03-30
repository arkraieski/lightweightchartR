# Add a histogram series from a chart column

Add a histogram series from a chart column

## Usage

``` r
add_histogram(
  chart,
  column = NULL,
  pane = "histogram",
  name = NULL,
  color = "#7c3aed",
  pane_height = 1
)
```

## Arguments

- chart:

  A `lightweightchartR` chart object.

- column:

  Source column. Defaults to the close column.

- pane:

  Target pane.

- name:

  Optional series name.

- color:

  Series color.

- pane_height:

  Relative pane height for the target pane.

## Value

The updated chart object.

# Add volume bars

Add volume bars

## Usage

``` r
add_volume(
  chart,
  pane = "price",
  color_up = "#26a69a",
  color_down = "#ef5350",
  pane_height = 0.6
)
```

## Arguments

- chart:

  A `lightweightchartR` chart object.

- pane:

  Target pane. Defaults to `"volume"`.

- color_up, color_down:

  Colors for rising/falling volume bars.

- pane_height:

  Relative pane height for the volume pane.

## Value

The updated chart object.

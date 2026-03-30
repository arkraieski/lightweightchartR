# Add RSI in a separate pane by default

Add RSI in a separate pane by default

## Usage

``` r
add_rsi(
  chart,
  n = 14,
  column = NULL,
  pane = "rsi",
  color = "#dc2626",
  pane_height = 0.8,
  ...
)
```

## Arguments

- chart:

  A `lightweightchartR` chart object.

- n:

  Window size.

- column:

  Source column. Defaults to the close column.

- pane:

  Target pane.

- color:

  Series color.

- pane_height:

  Relative pane height for the RSI pane.

- ...:

  Reserved for future extensions.

## Value

The updated chart object.

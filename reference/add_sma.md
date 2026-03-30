# Add a simple moving average

Add a simple moving average

## Usage

``` r
add_sma(chart, n = 20, column = NULL, pane = "price", color = "#2563eb", ...)
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

- ...:

  Reserved for future extensions.

## Value

The updated chart object.

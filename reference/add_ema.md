# Add an exponential moving average

Add an exponential moving average

## Usage

``` r
add_ema(chart, n = 20, column = NULL, pane = "price", color = "#ea580c", ...)
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

# Shiny bindings for lightweightchartR

Shiny bindings for lightweightchartR

## Usage

``` r
lightweightchartROutput(outputId, width = "100%", height = "480px")

renderLightweightchartR(expr, env = parent.frame(), quoted = FALSE)
```

## Arguments

- outputId:

  Output variable to read from.

- width, height:

  CSS dimensions for the widget container.

- expr:

  An expression that generates a chart.

- env:

  The environment in which to evaluate `expr`.

- quoted:

  Is `expr` already quoted?

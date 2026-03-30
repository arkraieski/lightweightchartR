# lightweightchartR

`lightweightchartR` is built for quantmod users who want
TradingView-style interactive charts in a pipe-first workflow.

``` r
library(lightweightchartR)

x <- xts::xts(
  data.frame(
    Open = 100 + seq_len(30),
    High = 101 + seq_len(30) + sin(seq_len(30) / 6),
    Low = 99 + seq_len(30) - sin(seq_len(30) / 6),
    Close = 100 + seq_len(30) + sin(seq_len(30) / 4),
    Volume = 1000 + seq_len(30) * 25
  ),
  order.by = as.Date("2024-01-01") + 0:29
)

x |>
  lwc_chart(theme = "dark") |>
  add_volume() |>
  add_sma(n = 3) |>
  add_rsi()
#> Registered S3 method overwritten by 'quantmod':
#>   method            from
#>   as.zoo.data.frame zoo
```

For users migrating from quantmod,
[`chart_series_lwc()`](https://arkraieski.github.io/lightweightchartR/reference/chart_series_lwc.md)
supports a compact bridge for common workflows:

``` r
chart_series_lwc(
  x,
  TA = "addVo();addSMA(n = 3);addRSI()"
)
```

test_that("vignette-style workflow supports default RSI window", {
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

  chart <- x |>
    lwc_chart(theme = "dark") |>
    add_volume() |>
    add_sma(n = 3) |>
    add_rsi()

  expect_s3_class(chart, "lightweightchartR")
  expect_equal(vapply(chart$x$spec$panes, `[[`, character(1), "id"), c("price", "rsi"))
})

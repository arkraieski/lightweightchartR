test_that("lwc_chart infers a candlestick series from OHLC data", {
  chart <- lwc_chart(sample_ohlcv())

  expect_s3_class(chart, "lightweightchartR")
  expect_equal(chart$x$spec$panes[[1]]$id, "price")
  expect_equal(chart$x$spec$panes[[1]]$series[[1]]$type, "candlestick")
})

test_that("lwc_chart falls back to a line series for close-only data", {
  x <- sample_ohlcv()[, "Close", drop = FALSE]
  chart <- lwc_chart(x)

  expect_equal(chart$x$spec$panes[[1]]$series[[1]]$type, "line")
})

test_that("subset strings are applied through xts", {
  x <- sample_ohlcv()
  chart <- lwc_chart(x, subset = "2024-01-10/2024-01-15")
  series <- chart$x$spec$panes[[1]]$series[[1]]$data

  expect_equal(length(series), 6)
  expect_equal(series[[1]]$time, as.numeric(as.POSIXct("2024-01-10", tz = "UTC")))
})

test_that("pipe-based layer helpers append panes and series", {
  chart <- sample_ohlcv() |>
    lwc_chart() |>
    add_volume() |>
    add_sma(n = 5) |>
    add_rsi()

  expect_equal(length(chart$x$spec$panes), 2)
  expect_equal(chart$x$spec$panes[[1]]$id, "price")
  expect_equal(chart$x$spec$panes[[2]]$id, "rsi")
  expect_equal(length(chart$x$spec$panes[[1]]$series), 3)
  expect_equal(chart$x$spec$panes[[1]]$height, 3)
})

test_that("volume pane uses its own visible scale", {
  chart <- sample_ohlcv() |>
    lwc_chart() |>
    add_volume(pane = "volume")

  expect_equal(chart$x$spec$panes[[2]]$series[[1]]$options$priceScaleId, "right")
})

test_that("series records serialize as flat point objects", {
  chart <- sample_ohlcv() |>
    lwc_chart() |>
    add_volume()

  price_json <- jsonlite::toJSON(
    chart$x$spec$panes[[1]]$series[[1]]$data[1:2],
    auto_unbox = TRUE,
    dataframe = "rows",
    null = "null",
    digits = NA
  )

  volume_json <- jsonlite::toJSON(
    chart$x$spec$panes[[1]]$series[[2]]$data[1:2],
    auto_unbox = TRUE,
    dataframe = "rows",
    null = "null",
    digits = NA
  )

  expect_false(grepl("^\\[\\[", price_json))
  expect_false(grepl("^\\[\\[", volume_json))
})

test_that("default volume overlays into the price pane with scale margins", {
  chart <- sample_ohlcv() |>
    lwc_chart() |>
    add_volume()

  expect_equal(chart$x$spec$panes[[1]]$series[[2]]$id, "volume")
  expect_equal(chart$x$spec$panes[[1]]$series[[2]]$options$priceScaleId, "")
  expect_equal(chart$x$spec$panes[[1]]$series[[1]]$scaleMargins$bottom, 0.22)
})

test_that("macd adds line and histogram series to its own pane", {
  chart <- sample_ohlcv() |>
    lwc_chart() |>
    add_macd()

  pane <- chart$x$spec$panes[[2]]
  types <- vapply(pane$series, `[[`, character(1), "type")
  expect_equal(pane$id, "macd")
  expect_equal(types, c("line", "line", "histogram"))
})

test_that("compatibility wrapper translates simple TA calls", {
  chart <- chart_series_lwc(sample_ohlcv(), TA = "addVo();addSMA(n = 10);addRSI()")

  expect_equal(vapply(chart$x$spec$panes, `[[`, character(1), "id"), c("price", "rsi"))
  expect_equal(length(chart$x$spec$panes[[1]]$series), 3)
})

test_that("rendered widget carries the expected dependencies", {
  chart <- sample_ohlcv() |>
    lwc_chart() |>
    add_volume()

  tags <- htmltools::renderTags(chart)
  expect_match(tags$html, "lightweightchartR", fixed = TRUE)
  dep_names <- vapply(tags$dependencies, `[[`, character(1), "name")
  expect_true("lightweight-charts" %in% dep_names)
})

test_that("ta tooltip options are exposed on chart metadata", {
  default_chart <- lwc_chart(sample_ohlcv())
  custom_chart <- lwc_chart(sample_ohlcv(), ta_tooltip = FALSE, ta_tooltip_threshold = 6)

  expect_true(default_chart$x$meta$ta_tooltip)
  expect_equal(default_chart$x$meta$ta_tooltip_threshold, 14)
  expect_false(custom_chart$x$meta$ta_tooltip)
  expect_equal(custom_chart$x$meta$ta_tooltip_threshold, 6)
})

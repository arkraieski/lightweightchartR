sample_ohlcv <- function() {
  idx <- as.Date("2024-01-01") + 0:89
  xts::xts(
    data.frame(
      Open = 100 + seq_along(idx),
      High = 101 + seq_along(idx) + sin(seq_along(idx) / 8),
      Low = 99 + seq_along(idx) - sin(seq_along(idx) / 8),
      Close = 100 + seq_along(idx) + sin(seq_along(idx) / 4),
      Volume = 1000 + seq_along(idx) * 25
    ),
    order.by = idx
  )
}

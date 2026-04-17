#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
  defaults <- list(
    n = 50000L,
    iterations = 5L,
    seed = 42L,
    profile = FALSE,
    profile_dir = file.path("tmp", "bench-profiles")
  )

  if (!length(args)) {
    return(defaults)
  }

  for (arg in args) {
    if (identical(arg, "--profile")) {
      defaults$profile <- TRUE
      next
    }

    parts <- strsplit(arg, "=", fixed = TRUE)[[1]]
    if (length(parts) != 2L || !nzchar(parts[[1]]) || !startsWith(parts[[1]], "--")) {
      stop(sprintf("Unsupported argument: %s", arg), call. = FALSE)
    }

    key <- sub("^--", "", parts[[1]])
    value <- parts[[2]]

    if (identical(key, "n")) {
      defaults$n <- as.integer(value)
    } else if (identical(key, "iterations")) {
      defaults$iterations <- as.integer(value)
    } else if (identical(key, "seed")) {
      defaults$seed <- as.integer(value)
    } else if (identical(key, "profile-dir")) {
      defaults$profile_dir <- value
    } else {
      stop(sprintf("Unsupported argument: %s", arg), call. = FALSE)
    }
  }

  defaults
}

load_package <- function() {
  if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
    return(asNamespace("lightweightchartR"))
  }

  if (requireNamespace("lightweightchartR", quietly = TRUE)) {
    return(asNamespace("lightweightchartR"))
  }

  stop("Need either `pkgload` or an installed `lightweightchartR` package.", call. = FALSE)
}

make_ohlcv <- function(n, seed = 42L) {
  set.seed(seed)
  idx <- as.POSIXct("2020-01-01 00:00:00", tz = "UTC") + seq_len(n) * 60
  base <- cumsum(stats::rnorm(n, mean = 0, sd = 0.35)) + 100
  open <- base + stats::rnorm(n, mean = 0, sd = 0.15)
  close <- base + stats::rnorm(n, mean = 0, sd = 0.15)
  high <- pmax(open, close) + abs(stats::rnorm(n, mean = 0, sd = 0.2))
  low <- pmin(open, close) - abs(stats::rnorm(n, mean = 0, sd = 0.2))
  volume <- round(stats::runif(n, min = 1000, max = 10000))

  xts::xts(
    data.frame(
      Open = open,
      High = high,
      Low = low,
      Close = close,
      Volume = volume,
      check.names = FALSE
    ),
    order.by = idx,
    tzone = "UTC"
  )
}

time_expr <- function(fn, iterations) {
  timings <- numeric(iterations)

  for (i in seq_len(iterations)) {
    gc()
    elapsed <- system.time(fn())[["elapsed"]]
    timings[[i]] <- unname(elapsed)
  }

  data.frame(
    min_s = min(timings),
    median_s = stats::median(timings),
    mean_s = mean(timings),
    max_s = max(timings),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

profile_expr <- function(label, fn, out_dir) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  out_file <- file.path(out_dir, paste0(label, ".out"))
  Rprof(out_file, interval = 0.001)
  on.exit(Rprof(NULL), add = TRUE)
  fn()
  Rprof(NULL)
  on.exit(NULL, add = FALSE)

  summary <- summaryRprof(out_file)
  top <- utils::head(summary$by.self, 10L)
  top <- data.frame(fn = rownames(top), top, row.names = NULL, check.names = FALSE)
  list(path = out_file, top = top)
}

ns_get <- function(ns, name) {
  get(name, envir = ns, inherits = FALSE)
}

format_summary <- function(label, summary_row) {
  sprintf(
    "%-24s min=%7.3f  median=%7.3f  mean=%7.3f  max=%7.3f",
    label,
    summary_row$min_s,
    summary_row$median_s,
    summary_row$mean_s,
    summary_row$max_s
  )
}

opts <- parse_args(args)
ns <- load_package()

lwc_chart <- ns_get(ns, "lwc_chart")
add_volume <- ns_get(ns, "add_volume")
add_sma <- ns_get(ns, "add_sma")
add_ema <- ns_get(ns, "add_ema")
add_rsi <- ns_get(ns, "add_rsi")
add_macd <- ns_get(ns, "add_macd")
chart_series_lwc <- ns_get(ns, "chart_series_lwc")
detect_mapping <- ns_get(ns, "detect_mapping")
xts_to_records <- ns_get(ns, "xts_to_records")
data_frame_to_records <- ns_get(ns, "data_frame_to_records")
build_main_series <- ns_get(ns, "build_main_series")
format_time_index <- ns_get(ns, "format_time_index")

x <- make_ohlcv(opts$n, seed = opts$seed)
mapping <- detect_mapping(x)

volume_frame <- data.frame(
  time = format_time_index(zoo::index(x)),
  value = as.numeric(x[, mapping$volume, drop = TRUE]),
  color = ifelse(
    as.numeric(x[, mapping$close, drop = TRUE]) >= as.numeric(x[, mapping$open, drop = TRUE]),
    "#26a69a",
    "#ef5350"
  ),
  stringsAsFactors = FALSE
)

benchmarks <- list(
  public_lwc_chart = function() invisible(lwc_chart(x)),
  public_with_volume = function() invisible(add_volume(lwc_chart(x))),
  public_layered = function() invisible(add_macd(add_rsi(add_ema(add_sma(add_volume(lwc_chart(x)), 20), 50)))),
  public_chart_series_lwc = function() invisible(chart_series_lwc(x, TA = "addVo();addSMA(n = 20);addEMA(n = 50);addRSI();addMACD()")),
  internal_xts_to_records_ohlc = function() invisible(xts_to_records(x, mapping[c("open", "high", "low", "close")])),
  internal_xts_to_records_close = function() invisible(xts_to_records(x, list(value = mapping$close))),
  internal_data_frame_to_records_volume = function() invisible(data_frame_to_records(volume_frame)),
  internal_build_main_series = function() invisible(build_main_series(x, mapping, "candles", "#26a69a", "#ef5350"))
)

cat(sprintf("Benchmarking chart build paths with n=%s rows, iterations=%s, seed=%s\n", opts$n, opts$iterations, opts$seed))
cat("Run this again after changes with the same arguments for a clean before/after comparison.\n\n")

results <- lapply(names(benchmarks), function(label) {
  summary_row <- time_expr(benchmarks[[label]], opts$iterations)
  cbind(case = label, summary_row, stringsAsFactors = FALSE)
})
results <- do.call(rbind, results)
rownames(results) <- NULL

cat("Timing summary (seconds)\n")
for (i in seq_len(nrow(results))) {
  cat(format_summary(results$case[[i]], results[i, , drop = FALSE]), "\n")
}

if (isTRUE(opts$profile)) {
  cat("\nProfiles\n")
  profile_cases <- c("public_lwc_chart", "public_layered", "internal_xts_to_records_ohlc")

  for (label in profile_cases) {
    profile <- profile_expr(label, benchmarks[[label]], opts$profile_dir)
    cat(sprintf("%s -> %s\n", label, profile$path))
    print(profile$top)
    cat("\n")
  }
}

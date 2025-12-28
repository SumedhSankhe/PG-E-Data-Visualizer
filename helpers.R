# Helper Functions for PG&E Data Visualizer
# Shared utility functions and calculation helpers

# Safe Division -----------------------------------------------------------
# Prevents division by zero errors
safe_divide <- function(numerator, denominator, default = 0) {
  if (is.null(denominator) || is.na(denominator) || denominator == 0) {
    return(default)
  }
  return(numerator / denominator)
}

# Safe Percentage ---------------------------------------------------------
# Calculates percentage with zero-division protection
safe_percentage <- function(part, whole, default = 0) {
  result <- safe_divide(part, whole, default) * 100
  return(round(result, 2))
}

# File Validation ---------------------------------------------------------
# Validates uploaded file for security
validate_upload_file <- function(file_info, session = NULL) {
  # Check if file exists
  if (is.null(file_info) || is.null(file_info$datapath)) {
    return(list(valid = FALSE, message = "No file selected"))
  }

  # Check file size
  file_size_mb <- file.info(file_info$datapath)$size / (1024^2)
  if (file_size_mb > MAX_UPLOAD_SIZE_MB) {
    msg <- sprintf("File size (%.1f MB) exceeds maximum allowed size (%d MB)",
                   file_size_mb, MAX_UPLOAD_SIZE_MB)
    if (!is.null(session)) {
      showNotification(msg, type = "error", duration = 5)
    }
    return(list(valid = FALSE, message = msg))
  }

  # Check file extension
  file_ext <- tolower(tools::file_ext(file_info$name))
  if (!file_ext %in% ALLOWED_FILE_EXTENSIONS) {
    msg <- sprintf("Invalid file type '%s'. Allowed: %s",
                   file_ext, paste(ALLOWED_FILE_EXTENSIONS, collapse = ", "))
    if (!is.null(session)) {
      showNotification(msg, type = "error", duration = 5)
    }
    return(list(valid = FALSE, message = msg))
  }

  return(list(valid = TRUE, message = "File valid"))
}

# Validate Required Columns -----------------------------------------------
# Ensures dataset has required columns
validate_required_columns <- function(data, session = NULL) {
  if (is.null(data) || nrow(data) == 0) {
    return(list(valid = FALSE, message = "Dataset is empty"))
  }

  missing_cols <- setdiff(DATA_REQUIRED_COLUMNS, names(data))

  if (length(missing_cols) > 0) {
    msg <- sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", "))
    if (!is.null(session)) {
      showNotification(msg, type = "error", duration = 10)
    }
    return(list(valid = FALSE, message = msg))
  }

  return(list(valid = TRUE, message = "All required columns present"))
}

# QC Analysis Calculation -------------------------------------------------
# Shared QC calculation logic to avoid duplication
calculate_qc_metrics <- function(df) {
  qc <- list()

  # Total records
  qc$total_records <- nrow(df)
  qc$date_range <- paste(min(as.Date(df$dttm_start)), "to", max(as.Date(df$dttm_start)))

  # Missing values
  qc$missing_values <- sum(is.na(df$value))
  qc$missing_pct <- safe_percentage(qc$missing_values, qc$total_records)

  # Negative and zero values
  qc$negative_values <- sum(df$value < 0, na.rm = TRUE)
  qc$zero_values <- sum(df$value == 0, na.rm = TRUE)
  qc$zero_pct <- safe_percentage(qc$zero_values, qc$total_records)

  # Outlier detection using IQR method
  Q1 <- quantile(df$value, 0.25, na.rm = TRUE)
  Q3 <- quantile(df$value, 0.75, na.rm = TRUE)
  IQR_val <- Q3 - Q1
  lower_bound <- Q1 - QC_OUTLIER_IQR_MULTIPLIER * IQR_val
  upper_bound <- Q3 + QC_OUTLIER_IQR_MULTIPLIER * IQR_val

  qc$outliers <- sum(df$value < lower_bound | df$value > upper_bound, na.rm = TRUE)
  qc$outlier_pct <- safe_percentage(qc$outliers, qc$total_records)
  qc$outlier_lower <- lower_bound
  qc$outlier_upper <- upper_bound

  # Summary statistics
  qc$mean_value <- round(mean(df$value, na.rm = TRUE), 3)
  qc$median_value <- round(median(df$value, na.rm = TRUE), 3)
  qc$min_value <- round(min(df$value, na.rm = TRUE), 3)
  qc$max_value <- round(max(df$value, na.rm = TRUE), 3)
  qc$sd_value <- round(sd(df$value, na.rm = TRUE), 3)

  # Data quality score
  issues <- qc$missing_pct + qc$outlier_pct + safe_percentage(qc$negative_values, qc$total_records)
  qc$quality_score <- max(0, 100 - issues)

  return(qc)
}

# Anomaly Detection - IQR Method ------------------------------------------
detect_anomalies_iqr <- function(df, sensitivity) {
  Q1 <- quantile(df$value, 0.25, na.rm = TRUE)
  Q3 <- quantile(df$value, 0.75, na.rm = TRUE)
  IQR_val <- Q3 - Q1

  # Adjust multiplier based on sensitivity (lower sensitivity = stricter)
  multiplier <- ANOMALY_IQR_BASE_MULTIPLIER + (VALID_SENSITIVITY_MAX - sensitivity) * ANOMALY_IQR_SENSITIVITY_FACTOR

  lower_bound <- Q1 - multiplier * IQR_val
  upper_bound <- Q3 + multiplier * IQR_val

  df[, is_anomaly := (value < lower_bound | value > upper_bound)]
  df[, anomaly_score := pmax(
    abs(value - lower_bound) / pmax(IQR_val, 0.01),  # Prevent division by zero
    abs(value - upper_bound) / pmax(IQR_val, 0.01)
  )]
  df[, expected_range_lower := lower_bound]
  df[, expected_range_upper := upper_bound]

  return(df)
}

# Cost Calculations - Rate Plan Comparison -------------------------------
compare_rate_plans <- function(df) {
  comparisons <- list()

  # TOU Plan
  tou_df <- copy(df)
  tou_df[, is_peak := hour >= DEFAULT_TOU_PEAK_START & hour <= DEFAULT_TOU_PEAK_END]
  tou_cost <- sum(tou_df[is_peak == TRUE]$value * DEFAULT_TOU_PEAK_RATE, na.rm = TRUE) +
    sum(tou_df[is_peak == FALSE]$value * DEFAULT_TOU_OFFPEAK_RATE, na.rm = TRUE)
  comparisons$TOU <- tou_cost

  # Tiered Plan
  daily_totals <- df[, .(daily_total = sum(value, na.rm = TRUE)), by = start_date]
  tier_cost <- sum(pmin(daily_totals$daily_total, DEFAULT_TIER1_LIMIT) * DEFAULT_TIER1_RATE, na.rm = TRUE) +
    sum(pmax(0, daily_totals$daily_total - DEFAULT_TIER1_LIMIT) * DEFAULT_TIER2_RATE, na.rm = TRUE)
  comparisons$Tiered <- tier_cost

  # Flat Rate
  flat_cost <- sum(df$value * DEFAULT_CUSTOM_RATE, na.rm = TRUE)
  comparisons$Flat <- flat_cost

  # EV Plan (super off-peak midnight to 6am)
  ev_df <- copy(df)
  ev_df[, period := ifelse(hour >= DEFAULT_EV_SUPER_OFFPEAK_START & hour < DEFAULT_EV_SUPER_OFFPEAK_END, "super_offpeak",
                            ifelse(hour >= DEFAULT_TOU_PEAK_START & hour <= DEFAULT_TOU_PEAK_END, "peak", "offpeak"))]
  ev_cost <- sum(ev_df[period == "peak"]$value * DEFAULT_EV_PEAK_RATE, na.rm = TRUE) +
    sum(ev_df[period == "offpeak"]$value * DEFAULT_EV_OFFPEAK_RATE, na.rm = TRUE) +
    sum(ev_df[period == "super_offpeak"]$value * DEFAULT_EV_SUPER_OFFPEAK_RATE, na.rm = TRUE)
  comparisons$EV <- ev_cost

  num_days <- length(unique(df$start_date))
  if (num_days == 0) num_days <- 1  # Prevent division by zero

  return(data.table(
    Plan = names(comparisons),
    Total_Cost = unlist(comparisons),
    Avg_Daily = safe_divide(unlist(comparisons), num_days)
  ))
}

# Input Validation - Peak Hours -------------------------------------------
validate_peak_hours <- function(peak_start, peak_end, session = NULL) {
  errors <- c()

  # Validate peak start
  if (is.null(peak_start) || is.na(peak_start)) {
    errors <- c(errors, "Peak start hour is required")
  } else if (peak_start < VALID_HOUR_MIN || peak_start > VALID_HOUR_MAX) {
    errors <- c(errors, sprintf("Peak start must be between %d and %d", VALID_HOUR_MIN, VALID_HOUR_MAX))
  }

  # Validate peak end
  if (is.null(peak_end) || is.na(peak_end)) {
    errors <- c(errors, "Peak end hour is required")
  } else if (peak_end < VALID_HOUR_MIN || peak_end > VALID_HOUR_MAX) {
    errors <- c(errors, sprintf("Peak end must be between %d and %d", VALID_HOUR_MIN, VALID_HOUR_MAX))
  }

  # Validate relationship
  if (length(errors) == 0 && peak_start >= peak_end) {
    errors <- c(errors, "Peak start hour must be before peak end hour")
  }

  if (length(errors) > 0 && !is.null(session)) {
    showNotification(paste(errors, collapse = "; "), type = "error", duration = 5)
  }

  return(list(valid = length(errors) == 0, errors = errors))
}

# Input Validation - Rate Values ------------------------------------------
validate_rate <- function(rate, rate_name, session = NULL) {
  if (is.null(rate) || is.na(rate)) {
    msg <- sprintf("%s is required", rate_name)
    if (!is.null(session)) {
      showNotification(msg, type = "error", duration = 5)
    }
    return(list(valid = FALSE, message = msg))
  }

  if (rate < VALID_RATE_MIN || rate > VALID_RATE_MAX) {
    msg <- sprintf("%s must be between $%.2f and $%.2f per kWh",
                   rate_name, VALID_RATE_MIN, VALID_RATE_MAX)
    if (!is.null(session)) {
      showNotification(msg, type = "error", duration = 5)
    }
    return(list(valid = FALSE, message = msg))
  }

  return(list(valid = TRUE, message = "Valid"))
}

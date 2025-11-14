# Configuration File for PG&E Data Visualizer
# All constants, thresholds, and configuration parameters

# File and Directory Constants ---------------------------------------------
DATA_DIR <- "data"  # Central data directory
LOG_DIR <- "logs"   # Log directory

# File Upload Limits -------------------------------------------------------
MAX_UPLOAD_SIZE_MB <- 50  # Maximum file size in MB
ALLOWED_FILE_EXTENSIONS <- c("csv", "tsv")

# Data Quality Thresholds -------------------------------------------------
QC_OUTLIER_IQR_MULTIPLIER <- 1.5
QC_MISSING_WARN_THRESHOLD <- 5   # Warn if > 5% missing
QC_MISSING_ERROR_THRESHOLD <- 1  # Error if > 1% missing (for alerts)
QC_OUTLIER_WARN_THRESHOLD <- 10  # Warn if > 10% outliers
QC_OUTLIER_ERROR_THRESHOLD <- 5  # Error if > 5% outliers (for alerts)
QC_QUALITY_EXCELLENT <- 90       # Quality score >= 90% is excellent
QC_QUALITY_GOOD <- 70            # Quality score >= 70% is good

# Anomaly Detection Constants ---------------------------------------------
ANOMALY_IQR_BASE_MULTIPLIER <- 1.5
ANOMALY_IQR_SENSITIVITY_FACTOR <- 0.3
ANOMALY_ZSCORE_BASE_THRESHOLD <- 3
ANOMALY_ZSCORE_SENSITIVITY_FACTOR <- 0.2
ANOMALY_STL_BASE_THRESHOLD <- 2.5
ANOMALY_STL_SENSITIVITY_FACTOR <- 0.15
ANOMALY_MA_BASE_THRESHOLD <- 2.5
ANOMALY_MA_SENSITIVITY_FACTOR <- 0.15
ANOMALY_MA_MIN_WINDOW <- 3
ANOMALY_MA_WINDOW_DIVISOR <- 24
ANOMALY_STL_MIN_OBSERVATIONS <- 24  # Minimum data points for STL
ANOMALY_SEVERITY_CRITICAL <- 2      # Score > 2 is critical
ANOMALY_SEVERITY_HIGH <- 1.5        # Score > 1.5 is high

# Pattern Recognition Constants -------------------------------------------
PATTERN_CV_EXCELLENT <- 70           # Consistency score >= 70% is excellent
PATTERN_CV_GOOD <- 50                # Consistency score >= 50% is good
PATTERN_WEEKEND_DIFF_SMALL <- 10     # < 10% difference is small
PATTERN_WEEKEND_DIFF_LARGE <- 25     # > 25% difference is large
PATTERN_CLUSTERING_MIN_CLUSTERS <- 2
PATTERN_CLUSTERING_MAX_CLUSTERS <- 7
PATTERN_CLUSTERING_DEFAULT <- 3
PATTERN_CLUSTERING_NSTART <- 25      # K-means nstart parameter
PATTERN_TOP_COST_HOURS <- 3          # Number of top cost hours to show

# Cost Optimization Constants ---------------------------------------------
COST_PEAK_HIGH_THRESHOLD <- 60       # Peak cost > 60% is concerning
COST_PEAK_MEDIUM_THRESHOLD <- 40     # Peak cost > 40% needs attention
COST_SAVINGS_EXCELLENT <- 50         # Savings > $50 is excellent
COST_SAVINGS_GOOD <- 20              # Savings > $20 is good
COST_PEAK_SHIFT_PERCENTILE <- 0.2    # Top 20% of peak usage for savings calc
COST_BEST_PLAN_THRESHOLD <- 0.95     # Recommend if plan saves >= 5%

# Default Rate Plan Parameters --------------------------------------------
DEFAULT_TOU_PEAK_START <- 16
DEFAULT_TOU_PEAK_END <- 21
DEFAULT_TOU_PEAK_RATE <- 0.45
DEFAULT_TOU_OFFPEAK_RATE <- 0.25

DEFAULT_TIER1_RATE <- 0.30
DEFAULT_TIER2_RATE <- 0.40
DEFAULT_TIER1_LIMIT <- 30

DEFAULT_CUSTOM_RATE <- 0.35

DEFAULT_EV_PEAK_RATE <- 0.50
DEFAULT_EV_OFFPEAK_RATE <- 0.28
DEFAULT_EV_SUPER_OFFPEAK_RATE <- 0.15
DEFAULT_EV_SUPER_OFFPEAK_START <- 0
DEFAULT_EV_SUPER_OFFPEAK_END <- 6

# UI Constants ------------------------------------------------------------
UI_DEBOUNCE_MS <- 500                # Debounce delay for numeric inputs in ms
UI_DATATABLE_PAGE_LENGTH <- 25       # Default page length for data tables
UI_DATATABLE_MAX_ROWS <- 1000        # Max rows before forcing server-side
UI_PLOT_HEIGHT <- 400                # Default plot height in pixels

# Data Processing Constants -----------------------------------------------
DATA_EXPECTED_FREQUENCY_HOURS <- 1   # Expected hourly data
DATA_TIME_GAP_THRESHOLD <- 1.5       # Gaps > 1.5 hours are flagged
DATA_REQUIRED_COLUMNS <- c("dttm_start", "hour", "value")

# Validation Ranges -------------------------------------------------------
VALID_HOUR_MIN <- 0
VALID_HOUR_MAX <- 23
VALID_RATE_MIN <- 0
VALID_RATE_MAX <- 2
VALID_SENSITIVITY_MIN <- 1
VALID_SENSITIVITY_MAX <- 10
VALID_TIER_LIMIT_MIN <- 0
VALID_TIER_LIMIT_MAX <- 1000

# Rate Plan Definitions ---------------------------------------------------
RATE_PLANS <- c("Time of Use", "Tiered Rate Plan", "Solar & Renewable Energy Plan",
                "Electric Vehicle Base Plan", "SmartRate Add-on")

RATE_TIERS <- list(
  "Time of Use" = c("E-TOU-C", "E-TOU-D"),
  "Tiered Rate Plan" = c("T1 (100% baseline)", "T2 (101%-400% baseline)",
                         "T3 (> 400% baseline)"),
  "Electric Vehicle Base Plan" = c('EV2-A', 'EV-B'),
  "Solar & Renewable Energy Plan" = c("COMING-SOON"),
  "SmartRate Add-on" = c("COMING-SOON")
)

RATE_HOURS <- list(
  "E-TOU-C" = c(16, 21),
  "E-TOU-D" = c(17, 20)
)

AGG_CHOICES <- c('Day', 'Week', 'Month', 'Year')

# Logging Configuration ---------------------------------------------------
LOG_LEVEL_DEV <- "DEBUG"
LOG_LEVEL_PROD <- "INFO"
LOG_DIR <- "logs"

# Environment Detection ---------------------------------------------------
get_environment <- function() {
  env <- Sys.getenv("R_ENV", "development")
  return(env)
}

get_log_level <- function() {
  env <- get_environment()
  if (env == "production") {
    return(LOG_LEVEL_PROD)
  } else {
    return(LOG_LEVEL_DEV)
  }
}

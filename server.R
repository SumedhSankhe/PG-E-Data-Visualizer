function(input, output, session) {
  log_info("[server] Session started: {session$token}")

  onStop(function() {
    log_info("[server] Application closing (session: {session$token})")
    # Flush logger (tee appender writes synchronously, so usually fine)
    stopApp()
  })

  # Initialize modules with logging
  log_debug("[server] Init home module")
  homeServer('home')
  log_debug("[server] Init loadData module")
  dt <- loadServer('loadData')

  # Global Date Range Filter UI ----
  output$global_date_range <- renderUI({
    req(dt())

    # Get min and max dates from data
    data_min_date <- as.Date(min(dt()$dttm_start))
    data_max_date <- as.Date(max(dt()$dttm_start))

    # Default to full range
    default_start <- data_min_date
    default_end <- data_max_date

    log_info("[server] Global date range initialized: {data_min_date} to {data_max_date}")

    dateRangeInput(
      inputId = 'global_dates',
      label = 'Global Date Filter',
      start = default_start,
      end = default_end,
      min = data_min_date,
      max = data_max_date,
      width = '100%'
    )
  })

  # Global Filtered Data Reactive ----
  filtered_dt <- reactive({
    req(dt())
    req(input$global_dates)

    validate(
      need(!is.na(input$global_dates[1]), 'Select a start date'),
      need(!is.na(input$global_dates[2]), 'Select an end date')
    )

    df <- copy(dt())
    df[, start_date := as.Date(dttm_start)]
    df_filtered <- df[start_date >= input$global_dates[1] & start_date <= input$global_dates[2]]

    log_info("[server] Global filter applied: {nrow(df_filtered)} records from {input$global_dates[1]} to {input$global_dates[2]}")
    return(df_filtered)
  })

  log_debug("[server] Init qc module")
  qcServer('qc', dt = filtered_dt)
  log_debug("[server] Init anomaly module")
  anomalyServer('anomaly', dt = filtered_dt)
  log_debug("[server] Init pattern module")
  patternServer('pattern', dt = filtered_dt)
  log_debug("[server] Init cost module")
  costServer('cost', dt = filtered_dt)

  # Enable/Disable Download Button based on date selection ----
  observe({
    if (is.null(input$global_dates) || is.na(input$global_dates[1]) || is.na(input$global_dates[2])) {
      shinyjs::disable("download_complete_report")
    } else {
      shinyjs::enable("download_complete_report")
    }
  })

  # Download Complete Report Handler ----
  output$download_complete_report <- downloadHandler(
    filename = function() {
      paste0("PGE_Complete_Analysis_Report_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      req(filtered_dt())

      logger::log_info("Generating complete analysis report")

      df <- copy(filtered_dt())
      df[, start_date := as.Date(dttm_start)]

      # Create workbook
      wb <- openxlsx::createWorkbook()

      ## Sheet 1: Overview/Summary ----
      openxlsx::addWorksheet(wb, "Overview")

      overview_data <- data.frame(
        Metric = c("Report Generated", "Analysis Period", "Total Records",
                  "Date Range", "Total Days", "Average Daily Consumption (kWh)"),
        Value = c(
          as.character(Sys.time()),
          paste(min(df$start_date), "to", max(df$start_date)),
          format(nrow(df), big.mark = ","),
          paste(min(df$start_date), "to", max(df$start_date)),
          length(unique(df$start_date)),
          round(sum(df$value, na.rm = TRUE) / length(unique(df$start_date)), 2)
        )
      )

      openxlsx::writeData(wb, "Overview", overview_data)
      openxlsx::addStyle(wb, "Overview",
                        style = openxlsx::createStyle(textDecoration = "bold"),
                        rows = 1, cols = 1:2, gridExpand = TRUE)

      ## Sheet 2: QC Results ----
      openxlsx::addWorksheet(wb, "Quality Control")

      # Run QC analysis
      Q1 <- quantile(df$value, 0.25, na.rm = TRUE)
      Q3 <- quantile(df$value, 0.75, na.rm = TRUE)
      IQR_val <- Q3 - Q1
      lower_bound <- Q1 - 1.5 * IQR_val
      upper_bound <- Q3 + 1.5 * IQR_val

      qc_data <- data.frame(
        Metric = c("Total Records", "Missing Values", "Missing %",
                  "Negative Values", "Zero Values", "Outliers", "Outlier %",
                  "Mean (kWh)", "Median (kWh)", "Min (kWh)", "Max (kWh)", "Std Dev",
                  "Quality Score (%)"),
        Value = c(
          nrow(df),
          sum(is.na(df$value)),
          round((sum(is.na(df$value)) / nrow(df)) * 100, 2),
          sum(df$value < 0, na.rm = TRUE),
          sum(df$value == 0, na.rm = TRUE),
          sum(df$value < lower_bound | df$value > upper_bound, na.rm = TRUE),
          round((sum(df$value < lower_bound | df$value > upper_bound, na.rm = TRUE) / nrow(df)) * 100, 2),
          round(mean(df$value, na.rm = TRUE), 3),
          round(median(df$value, na.rm = TRUE), 3),
          round(min(df$value, na.rm = TRUE), 3),
          round(max(df$value, na.rm = TRUE), 3),
          round(sd(df$value, na.rm = TRUE), 3),
          round(max(0, 100 - (sum(is.na(df$value)) / nrow(df)) * 100 -
                    (sum(df$value < lower_bound | df$value > upper_bound, na.rm = TRUE) / nrow(df)) * 100), 1)
        )
      )

      openxlsx::writeData(wb, "Quality Control", qc_data)
      openxlsx::addStyle(wb, "Quality Control",
                        style = openxlsx::createStyle(textDecoration = "bold"),
                        rows = 1, cols = 1:2, gridExpand = TRUE)

      ## Sheet 3: Anomaly Detection (IQR method) ----
      openxlsx::addWorksheet(wb, "Anomalies")

      df[, is_anomaly := (value < lower_bound | value > upper_bound)]
      df[, anomaly_score := pmax(
        abs(value - lower_bound) / IQR_val,
        abs(value - upper_bound) / IQR_val
      )]

      anomalies <- df[is_anomaly == TRUE, .(
        Timestamp = dttm_start,
        Value = round(value, 3),
        Expected_Min = round(lower_bound, 3),
        Expected_Max = round(upper_bound, 3),
        Anomaly_Score = round(anomaly_score, 3)
      )][order(-Anomaly_Score)]

      if (nrow(anomalies) > 0) {
        openxlsx::writeData(wb, "Anomalies", anomalies)
        openxlsx::addStyle(wb, "Anomalies",
                          style = openxlsx::createStyle(textDecoration = "bold"),
                          rows = 1, cols = 1:ncol(anomalies), gridExpand = TRUE)
      } else {
        openxlsx::writeData(wb, "Anomalies", data.frame(Message = "No anomalies detected in this period"))
      }

      ## Sheet 4: Pattern Analysis ----
      openxlsx::addWorksheet(wb, "Pattern Analysis")

      # Daily hourly pattern
      hourly_pattern <- df[, .(
        Hour = hour,
        Mean_kWh = round(mean(value, na.rm = TRUE), 3),
        Min_kWh = round(min(value, na.rm = TRUE), 3),
        Max_kWh = round(max(value, na.rm = TRUE), 3),
        Std_Dev = round(sd(value, na.rm = TRUE), 3),
        Count = .N
      ), by = hour][order(hour)]

      openxlsx::writeData(wb, "Pattern Analysis", hourly_pattern)
      openxlsx::addStyle(wb, "Pattern Analysis",
                        style = openxlsx::createStyle(textDecoration = "bold"),
                        rows = 1, cols = 1:ncol(hourly_pattern), gridExpand = TRUE)

      ## Sheet 5: Cost Analysis (TOU default) ----
      openxlsx::addWorksheet(wb, "Cost Analysis")

      # Default TOU rate plan (16-21 peak hours)
      df[, is_peak := hour >= 16 & hour <= 21]
      df[, rate := ifelse(is_peak, 0.45, 0.25)]
      df[, cost := value * rate]

      cost_summary <- data.frame(
        Metric = c("Rate Plan", "Peak Hours", "Peak Rate ($/kWh)", "Off-Peak Rate ($/kWh)",
                  "Total Cost ($)", "Peak Cost ($)", "Off-Peak Cost ($)", "Peak Cost %",
                  "Average Daily Cost ($)", "Peak Consumption (kWh)", "Off-Peak Consumption (kWh)"),
        Value = c(
          "Time of Use (TOU)",
          "16:00 - 21:00",
          "0.45",
          "0.25",
          round(sum(df$cost, na.rm = TRUE), 2),
          round(sum(df[is_peak == TRUE]$cost, na.rm = TRUE), 2),
          round(sum(df[is_peak == FALSE]$cost, na.rm = TRUE), 2),
          round((sum(df[is_peak == TRUE]$cost, na.rm = TRUE) / sum(df$cost, na.rm = TRUE)) * 100, 1),
          round(sum(df$cost, na.rm = TRUE) / length(unique(df$start_date)), 2),
          round(sum(df[is_peak == TRUE]$value, na.rm = TRUE), 2),
          round(sum(df[is_peak == FALSE]$value, na.rm = TRUE), 2)
        )
      )

      openxlsx::writeData(wb, "Cost Analysis", cost_summary)
      openxlsx::addStyle(wb, "Cost Analysis",
                        style = openxlsx::createStyle(textDecoration = "bold"),
                        rows = 1, cols = 1:2, gridExpand = TRUE)

      # Save workbook
      openxlsx::saveWorkbook(wb, file, overwrite = TRUE)

      logger::log_info("Complete report generated successfully")
    }
  )

  # Reactive watcher for dataset size changes
  observe({
    d <- filtered_dt()
    if (!is.null(d)) {
      log_trace("[server] Filtered dataset snapshot rows={nrow(d)} cols={ncol(d)}")
    }
  })
}
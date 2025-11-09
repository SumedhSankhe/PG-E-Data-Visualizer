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

  # Reactive watcher for dataset size changes
  observe({
    d <- filtered_dt()
    if (!is.null(d)) {
      log_trace("[server] Filtered dataset snapshot rows={nrow(d)} cols={ncol(d)}")
    }
  })
}
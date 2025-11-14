
DATA_DIR <- "data"               # central data directory
DEFAULT_DATA_FILE <- file.path(DATA_DIR, "meterData.rds")

loadUI <- function(id, label = 'loadData') {
  ns <- NS(id)
  fluidPage(
    # Help Box
    fluidRow(
      column(
        width = 12,
        div(
          style = "margin-bottom: 20px; border: 1px solid #e5e7eb; border-radius: 4px; background-color: #ffffff; box-shadow: 0 1px 2px rgba(0,0,0,0.05);",
          div(
            style = "padding: 12px 20px; background: linear-gradient(135deg, #eff6ff 0%, #ffffff 100%); border-bottom: 1px solid #e5e7eb; cursor: pointer; border-radius: 4px 4px 0 0;",
            onclick = "$(this).next().slideToggle(200);",
            tags$span(
              style = "font-size: 15px; font-weight: 500; color: #3b82f6;",
              icon('question-circle'), ' Need help? Click to expand'
            )
          ),
          div(
            style = "display: none; padding: 20px;",
            p(
              style = "font-size: 14px; line-height: 1.6; color: #374151;",
              "Upload your PG&E smart meter data file (CSV or TSV format) or use the included sample dataset to explore the application."
            ),
            tags$ul(
              style = "font-size: 14px; line-height: 1.6; color: #4b5563;",
              tags$li(tags$strong("Required columns:"), " dttm_start (timestamp), hour (0-23), value (kWh), day, day2"),
              tags$li(tags$strong("Timestamp format:"), " YYYY-MM-DD HH:MM:SS (e.g., 2024-01-01 14:00:00)"),
              tags$li(tags$strong("No file?"), " The sample dataset will load automatically - perfect for trying out features!")
            ),
            p(
              style = "font-size: 14px; line-height: 1.6; margin-top: 10px; color: #374151;",
              tags$strong("Next step:"), " After loading data, use the ", tags$strong("sidebar date filter"),
              " to select your analysis period, then proceed to Quality Control to verify data quality."
            )
          )
        )
      )
    ),

    fluidRow(
      column(
        width = 3,
        shinydashboard::box(
          title = 'Data Upload', width = 12, status = 'primary',
          fileInput(
            inputId = ns('localfile'),
            label = tags$span(icon('upload'), ' Upload meter data'),
            accept = c('.csv', '.tsv'),
            buttonLabel = "Browse...",
            placeholder = "No file selected"
          ),
          div(style = 'margin-top:-10px'),
          tags$div(
            style = "padding: 10px; background-color: #ecfeff; border-radius: 4px; border-left: 3px solid #06b6d4;",
            tags$small(
              style = "font-size: 13px; color: #0e7490;",
              icon('lightbulb'), " ", tags$strong("Tip:"), " Accepted formats: CSV, TSV"
            )
          ),
          conditionalPanel(
            condition = sprintf("typeof input['%s'] === 'undefined' || input['%s'].length === 0", ns('localfile'), ns('localfile')),
            tags$div(
              style = "margin-top: 15px; padding: 10px; background-color: #fef3c7; border-radius: 4px; border-left: 3px solid #f59e0b;",
              tags$small(
                style = "font-size: 13px; color: #92400e;",
                icon('database'), " Using sample data: ", tags$code(basename(DEFAULT_DATA_FILE))
              )
            )
          )
        )
      ),
      column(
        width = 9,
        shinydashboard::box(
          title = tags$span(icon('table'), ' Data Preview'),
          width = 12,
          status = 'warning',
          DT::dataTableOutput(outputId = ns('tableOutput')),
          tags$hr(),
          tags$div(
            style = "padding: 10px;",
            tags$strong(icon('info-circle'), " Dataset Info: "),
            textOutput(outputId = ns('dataMeta'), inline = TRUE)
          )
        )
      )
    )
  )
}

loadServer <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      # Reactive that loads user file or fallback RDS
      dat <- reactive({
        user_file <- input$localfile

        if (!is.null(user_file) && !is.null(user_file$datapath)) {
          log_info("[loadData] User file upload detected: {user_file$name}")

          # Validate file upload
          validation <- validate_upload_file(user_file, session)
          if (!validation$valid) {
            log_error("[loadData] File validation failed: {validation$message}")
            showNotification(
              paste("Upload failed:", validation$message),
              type = "error",
              duration = 10
            )
            # Return fallback data instead of NULL
            log_info("[loadData] Using fallback RDS after validation failure")
            return(read_rds_safely(DEFAULT_DATA_FILE))
          }

          # Read file with error handling
          df <- tryCatch({
            data.table::fread(user_file$datapath)
          }, error = function(e) {
            log_error("[loadData] Failed reading uploaded file: {e$message}")
            showNotification(
              paste("Error reading file:", e$message),
              type = "error",
              duration = 10
            )
            NULL
          })

          if (is.null(df)) {
            log_warn("[loadData] File read returned NULL, using fallback")
            return(read_rds_safely(DEFAULT_DATA_FILE))
          }

          log_info("[loadData] Uploaded file rows={nrow(df)} cols={ncol(df)}")

          # Validate required columns
          col_validation <- validate_required_columns(df, session)
          if (!col_validation$valid) {
            log_error("[loadData] Column validation failed: {col_validation$message}")
            showNotification(
              paste("Invalid data structure:", col_validation$message),
              type = "error",
              duration = 10
            )
            return(read_rds_safely(DEFAULT_DATA_FILE))
          }

          log_info("[loadData] File upload successful and validated")
          showNotification(
            paste("File uploaded successfully:", user_file$name),
            type = "message",
            duration = 3
          )
          return(df)
        }

        # Fallback to default RDS
        log_info("[loadData] Using fallback RDS: {DEFAULT_DATA_FILE}")
        read_rds_safely(DEFAULT_DATA_FILE)
      })

      # Data validity check (additional monitoring)
      observe({
        d <- dat()
        if (is.null(d)) {
          log_warn("[loadData] Data reactive is NULL; table will not render")
          showNotification(
            "No data available. Please upload a valid file.",
            type = "warning",
            duration = 5
          )
        } else {
          log_debug("[loadData] Data loaded successfully with {nrow(d)} rows")
        }
      })

      output$tableOutput <- DT::renderDataTable({
        req(dat())
        data <- dat()

        # Use server-side processing for large datasets
        use_server_side <- nrow(data) > UI_DATATABLE_MAX_ROWS

        DT::datatable(
          data,
          options = list(
            scrollX = TRUE,
            scrollCollapse = TRUE,
            pageLength = UI_DATATABLE_PAGE_LENGTH,
            serverSide = use_server_side,
            processing = TRUE,
            dom = 'Bfrtip',
            buttons = c('copy', 'csv', 'excel'),
            order = list(list(0, 'asc'))  # Sort by first column (timestamp)
          ),
          filter = 'top',
          class = 'cell-border stripe hover'
        )
      })

      output$dataMeta <- renderText({
        d <- dat()
        if (is.null(d)) {
          return("No data loaded.")
        }
        paste0("Rows: ", nrow(d), " | Cols: ", ncol(d))
      })

      # Return reactive dataset for downstream modules
      return(dat)
    }
  )
}
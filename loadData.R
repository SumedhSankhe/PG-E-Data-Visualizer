
DATA_DIR <- "data"               # central data directory
DEFAULT_DATA_FILE <- file.path(DATA_DIR, "meterData.rds")

loadUI <- function(id, label = 'loadData') {
  ns <- NS(id)
  fluidPage(
    # Help Box
    fluidRow(
      shinydashboard::box(
        width = 12,
        status = 'info',
        solidHeader = FALSE,
        collapsible = TRUE,
        collapsed = TRUE,
        title = tags$span(icon('question-circle'), ' Need help? Click to expand'),
        p(
          style = "font-size: 14px; line-height: 1.6;",
          "Upload your PG&E smart meter data file (CSV or TSV format) or use the included sample dataset to explore the application."
        ),
        tags$ul(
          style = "font-size: 14px; line-height: 1.6;",
          tags$li(tags$strong("Required columns:"), " dttm_start (timestamp), hour (0-23), value (kWh), day, day2"),
          tags$li(tags$strong("Timestamp format:"), " YYYY-MM-DD HH:MM:SS (e.g., 2024-01-01 14:00:00)"),
          tags$li(tags$strong("No file?"), " The sample dataset will load automatically - perfect for trying out features!")
        ),
        p(
          style = "font-size: 14px; line-height: 1.6; margin-top: 10px;",
          tags$strong("Next step:"), " After loading data, use the ", tags$strong("sidebar date filter"),
          " to select your analysis period, then proceed to Quality Control to verify data quality."
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
            style = "padding: 10px; background-color: #d1ecf1; border-radius: 5px; border-left: 3px solid #17a2b8;",
            tags$small(
              style = "font-size: 13px;",
              icon('lightbulb'), " ", tags$strong("Tip:"), " Accepted formats: CSV, TSV"
            )
          ),
          conditionalPanel(
            condition = sprintf("typeof input['%s'] === 'undefined' || input['%s'].length === 0", ns('localfile'), ns('localfile')),
            tags$div(
              style = "margin-top: 15px; padding: 10px; background-color: #fff3cd; border-radius: 5px; border-left: 3px solid #ffc107;",
              tags$small(
                style = "font-size: 13px;",
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
        user_path <- input$localfile$datapath
        if (!is.null(user_path) && nzchar(user_path)) {
          log_info("[loadData] User file upload detected: {basename(user_path)}")
          df <- tryCatch({
            data.table::fread(user_path)
          }, error = function(e) {
            log_error("[loadData] Failed reading uploaded file: {e$message}")
            NULL
          })
          if (!is.null(df)) {
            log_info("[loadData] Uploaded file rows={nrow(df)} cols={ncol(df)}")
          }
          return(df)
        }
        # Fallback to default RDS
        log_info("[loadData] Using fallback RDS: {DEFAULT_DATA_FILE}")
        read_rds_safely(DEFAULT_DATA_FILE)
      })

      # Data validity check
      observe({
        d <- dat()
        if (is.null(d)) {
          log_warn("[loadData] Data reactive is NULL; table will not render")
        } else {
          # Example required columns check
          required_cols <- c("dttm_start", "hour", "value")
          missing <- setdiff(required_cols, names(d))
          if (length(missing) > 0) {
            log_warn("[loadData] Missing required columns: {paste(missing, collapse=', ')}")
          } else {
            log_debug("[loadData] All required columns present")
          }
        }
      })

      output$tableOutput <- DT::renderDataTable({
        req(dat())
        DT::datatable(dat(), options = list(scrollX = TRUE, scrollCollapse = TRUE))
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
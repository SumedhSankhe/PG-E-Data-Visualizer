
DATA_DIR <- "data"               # central data directory
DEFAULT_DATA_FILE <- file.path(DATA_DIR, "meterData.rds")

loadUI <- function(id, label = 'loadData') {
  ns <- NS(id)
  fluidPage(
    shinydashboard::box(
      title = 'Data Upload', width = 3, status = 'primary',
      fileInput(
        inputId = ns('localfile'),
        label = 'Upload meter data (.csv/.tsv)',
        accept = c('.csv', '.tsv')
      ),
      div(style = 'margin-top:-10px'),
      helpText("If no file provided, the bundled sample data is used."),
      conditionalPanel(
        condition = sprintf("typeof input['%s'] === 'undefined' || input['%s'].length === 0", ns('localfile'), ns('localfile')),
        tags$small(paste0("Fallback: ", DEFAULT_DATA_FILE))
      )
    ),
    shinydashboard::box(
      title = 'Data Table', width = 9, status = 'warning',
      DT::dataTableOutput(outputId = ns('tableOutput')),
      tags$small(textOutput(outputId = ns('dataMeta')))
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

analyseUI <- function(id){
  ns <- NS(id)
  h3('Analysis')
  fluidPage(
    column(4,
           shinydashboard::box(
             title = 'Time Series Control Panel', status = 'warning',
             uiOutput(outputId = ns('dateRange'))
           )
    ),
    column(8,
           shinydashboard::box(
             title = 'Time Series Plot', status = 'warning',
             div(
               style='width:1000px;overflow-x: scroll;height:1000px;overflow-y: scroll;',
               shinycssloaders::withSpinner(
                 plotly::plotlyOutput(outputId = ns("tsplot")))
             )
           )
    )
  )
}



analyseServer <- function(id, data){
  moduleServer(
    id,
    function(input, output, session){
      
      output$dateRange <- renderUI({
        req(data())
        ns <- session$ns
        dateRangeInput(inputId = ns('dates'), label = 'Date Range',
                       start = min(data()$Date), end = max(data()$Date))
      })
      
      
      output$tsplot <- plotly::renderPlotly({
        
        req(data())
        
      })
      
      
    }
  )
}
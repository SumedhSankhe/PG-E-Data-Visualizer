
analyseUI <- function(id, label = 'analyse'){
  ns <- NS(id)
  h3('Analysis')
  fluidPage(
    fluidRow(
      shinydashboard::box(width = 4,
                          title = 'Time Series Control Panel', status = 'warning',
                          uiOutput(outputId = ns('dateRange')),
                          fluidRow(
                            column(width = 6,
                                   selectInput(inputId = ns('month'), label = 'Select Month',
                                               choices = month.name),),
                            column(width = 6,
                                   selectInput(inputId = ns('year'), label = 'Select Year',
                                               choices = NULL))
                          ),
      ),
      shinydashboard::box( width = 8,
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



analyseServer <- function(id, dt){
  moduleServer(
    id,
    function(input, output, session){
      
      observe({
        browser()
        output$dateRange <- renderUI({
          req(dt())
          ns <- session$ns
          dateRangeInput(inputId = ns('dates'), label = 'Date Range',
                         start = min(dt()$Date), end = max(dt()$Date))
        })
      })
      
      
      observeEvent(input$month, {
        output$tsplot <- plotly::renderPlotly({
          req(dt())
          val <- which(month.name %in% input$month)
          plotly::ggplotly(
            ggplot(data = dt()[month == val], aes(x = hour, y = value))+
              geom_line(aes(group = day2), alpha = 0.4)+
              geom_smooth()+
              theme_bw()+
              labs(x ='Hour beginning' , y = 'kWh')+
              scale_x_continuous(breaks = seq(0,23,by=3))
          )
        })
      })
      
    }
  )
}

analyseUI <- function(id, label = 'analyse'){
  ns <- NS(id)
  h3('Analysis')
  shinyjs::useShinyjs()
  fluidPage(
    fluidRow(
      shinydashboard::box(width = 3,
                          title = 'Time Series Control Panel', status = 'warning',
                          column(width = 6,
                                 selectInput(inputId = ns('plan'),
                                             label = 'Type of Plan',
                                             choices = PLANS, selected = NULL),
                                 selectInput(inputId = ns('h1'), choices = NULL,
                                             label = NULL),
                                 numericInput(inputId = ns('dollar1'),
                                              label = "$/kWh Non-peak", value = 0,
                                              min = 0, max = 10, step = 0.001)
                          ),
                          column(width = 6,
                                 selectInput(inputId = ns('planTier'),
                                             label = 'Tier', choices = NULL,
                                             selected = NULL),
                                 selectInput(inputId = ns('h2'), choices = NULL,
                                             label = NULL),
                                 numericInput(inputId = ns('dollar2'),
                                              label = "$/kWh Peak", value = 0,
                                              min = 0, max = 10, step = 0.001)
                          ),
                          column(width = 12,
                                 uiOutput(outputId = ns('dateRange')),
                                 selectInput(inputId = ns('aggLvl'),
                                             label = "Aggregation Level",
                                             choices = AGGCHOICE,
                                             selected = AGGCHOICE[1]))
      ),
      shinydashboard::box( width = 9,
                           title = 'Time Series Plot', status = 'warning',
                           shinycssloaders::withSpinner(
                             plotly::plotlyOutput(outputId = ns("tsplot"))
                           )
      )
    ),
    fluidRow(
      shinydashboard::box(width = 3,),
      shinydashboard::box(width = 9, title = 'Distribution Per Hour',
                          status = 'warning',
                          shinycssloaders::withSpinner(
                            plotly::plotlyOutput(outputId = ns("boxplot"))
                          ))
    )
  )
}



analyseServer <- function(id, dt){
  moduleServer(
    id,
    function(input, output, session){

      observeEvent(input$plan,{
        updateSelectInput(inputId = 'planTier', choices = TIER[[input$plan]])
      })

      observeEvent(input$planTier, {

        if(names(TIER)[1] == input$plan){
          lapply(c('h1','h2','dollar1','dollar2'), shinyjs::showElement,
                 animType = 'fade', anim = T)

          updateSelectInput(inputId = 'h1', choices = 0:23,
                            selected = HOUR[[input$planTier]][1],
                            label =  'Start Hour')
          updateSelectInput(inputId = 'h2', choices = 0:23,
                            selected = HOUR[[input$planTier]][2],
                            label =  'End Hour')
        } else{
          lapply(c('h1','h2','dollar1','dollar2'), shinyjs::hideElement,
                 animType = 'fade', anim = T)
        }
      })


      observe({
        output$dateRange <- renderUI({
          req(dt())
          ns <- session$ns
          dateRangeInput(inputId = ns('dates'), label = 'Date Range',
                         start = min(dt()$dttm_start), end = max(dt()$dttm_start))
        })
      })

      listen <- reactive({
        list(input$dates)
      })

      observeEvent(listen(),{

        validate(
          need(!is.null(dt()), 'Require data'),
          need(!is.na(input$dates[1]), 'Select a date range'),
          need(!is.na(input$dates[2]), 'Select a date range')
        )

        df <- copy(dt())
        df[, ':='(start = as.Date(dttm_start))]
        df <- df[start >= input$dates[1] & start <= input$dates[2]]

        output$tsplot <- plotly::renderPlotly({
          plotly::ggplotly(
            ggplot(data = df,
                   aes(x = hour, y = value))+
              geom_line(aes(group = day2), alpha = 0.4)+
              geom_smooth()+
              theme_bw()+
              labs(x ='Hour beginning' , y = 'kWh')+
              scale_x_continuous(breaks = seq(0,23,by=3))
          ) |>
            plotly::config(
              modeBarButtonsToRemove = list(
                'pan2d', 'select2d', 'lasso2d', 'autoScale2d',
                'toggleSpikelines', 'hoverClosestCartesian', 'hoverCompareCartesian'
              ),
              displaylogo = FALSE
            )
        })


        output$boxplot <- plotly::renderPlotly({
          #browser()
          plotly::ggplotly(
            ggplot(data = df, aes(x = factor(hour), y = value))+
              geom_boxplot()+
              geom_jitter(aes(fill = factor(day)))+
              labs(x ='Hour beginning' , y = 'kWh', fill = 'Day')+
              theme_bw()
          ) |>
            plotly::config(
              modeBarButtonsToRemove = list(
                'pan2d', 'select2d', 'lasso2d', 'autoScale2d',
                'toggleSpikelines', 'hoverClosestCartesian', 'hoverCompareCartesian'
              ),
              displaylogo = FALSE
            )
        })


      })



    }
  )
}
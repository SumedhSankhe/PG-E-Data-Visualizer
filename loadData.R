
loadUI <- function(id, label = 'loadData'){
  ns <- NS(id)
  fluidPage(
    shinydashboard::box(
      title = 'Data Upload', width = 3, status = 'primary',
      fileInput(
        inputId = ns('localfile'),
        label = 'Upload a meter data',
        accept = c('.csv', '.tsv')
      ),
      div(style = 'margin-top:-25px'),
      a(href = '', 'Example Data', download = NA, target = '_blank')
    ),
    shinydashboard::box(
      title = 'Data Table', width = 9, status = 'warning',
      DT::dataTableOutput(
        outputId = ns('tableOutput')
      )
    )
  )
}

loadServer <- function(id){
  moduleServer(
    id,
    function(input, output, session){
      
      dat <- reactive({
        if(!is.null(input$localfile$datapath)){
          fread(input$localfile$datapath)
        }else{
          readRDS('meterData.rds')
        }
      })
      output$tableOutput <- DT::renderDataTable({
        req(dat())
        DT::datatable(dat(), options = list(scrollX = T, scrollCollapse = T))
      })
      return(dat)
    }
  )
}
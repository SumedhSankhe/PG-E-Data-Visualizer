
homeUI <- function(id, label = 'home'){
  ns <- NS(id)
  tagList(
    h3('Home'),
    fluidPage(
      #uiOutput(ns('markdown'))
    )
  )
}


homeServer <- function(id){
  moduleServer(
    id,
    function(input, output, session){
      output$markdown <- renderUI({
        HTML(
          markdown::markdownToHTML(
            knitr::knit('about.rmd', quiet = TRUE)
          )
        )
      })
    }
  )
}
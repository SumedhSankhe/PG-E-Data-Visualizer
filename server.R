function(input, output, session){
  
  onStop(function() {
    message("Application Closed")
    stopApp()
  })
  
  homeServer('home')
  dt <- loadServer('loadData')
  analyseServer('analyse', dt = dt)
}
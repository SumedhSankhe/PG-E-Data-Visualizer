function(input, output, session){
  
  onStop(function() {
    message("Application Closed")
    stopApp()
  })
  
  
  
  
  homeServer('home')
  loadServer('loadData')
  analyseServer('analyse')
}
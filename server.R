function(input, output, session) {
  log_info("[server] Session started: {session$token}")

  onStop(function() {
    log_info("[server] Application closing (session: {session$token})")
    # Flush logger (tee appender writes synchronously, so usually fine)
    stopApp()
  })

  # Initialize modules with logging
  log_debug("[server] Init home module")
  homeServer('home')
  log_debug("[server] Init loadData module")
  dt <- loadServer('loadData')
  log_debug("[server] Init qc module")
  qcServer('qc', dt = dt)
  log_debug("[server] Init anomaly module")
  anomalyServer('anomaly', dt = dt)
  log_debug("[server] Init pattern module")
  patternServer('pattern', dt = dt)
  log_debug("[server] Init cost module")
  costServer('cost', dt = dt)
  log_debug("[server] Init analyse module")
  analyseServer('analyse', dt = dt)

  # Reactive watcher for dataset size changes
  observe({
    d <- dt()
    if (!is.null(d)) {
      log_trace("[server] Dataset snapshot rows={nrow(d)} cols={ncol(d)}")
    }
  })
}
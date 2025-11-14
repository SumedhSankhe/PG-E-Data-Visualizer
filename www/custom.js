/**
 * Custom JavaScript for PG&E Data Visualizer
 * Handles UI interactions and collapsible sections
 */

// Wait for document to be ready
$(document).ready(function() {

  /**
   * Collapsible Section Handler
   * Handles click events on collapsible headers
   */
  function initializeCollapsibles() {
    // Use event delegation to handle dynamically created elements
    $(document).on('click', '.collapsible-header', function(e) {
      e.preventDefault();
      $(this).next('.collapsible-content').slideToggle(200);

      // Optional: Toggle icon or indicator
      var icon = $(this).find('.collapse-icon');
      if (icon.length > 0) {
        icon.toggleClass('rotated');
      }
    });
  }

  /**
   * File Upload Size Warning
   * Warns users before uploading large files
   */
  function initializeFileUploadWarnings() {
    $(document).on('change', 'input[type="file"]', function() {
      var file = this.files[0];
      if (file && file.size > 50 * 1024 * 1024) { // 50MB
        alert('Warning: File size is ' + (file.size / (1024*1024)).toFixed(1) +
              'MB. Large files may take a while to process.');
      }
    });
  }

  /**
   * Smooth Scroll for Anchors
   * Provides smooth scrolling for internal page links
   */
  function initializeSmoothScroll() {
    $('a[href^="#"]').on('click', function(e) {
      var target = $(this.getAttribute('href'));
      if (target.length) {
        e.preventDefault();
        $('html, body').stop().animate({
          scrollTop: target.offset().top - 100
        }, 300);
      }
    });
  }

  /**
   * Initialize Tooltips
   * Adds Bootstrap tooltips to elements with data-toggle="tooltip"
   */
  function initializeTooltips() {
    if (typeof $().tooltip === 'function') {
      $('[data-toggle="tooltip"]').tooltip();
    }
  }

  /**
   * Numeric Input Validation
   * Prevents invalid characters in numeric inputs
   */
  function initializeNumericValidation() {
    $(document).on('keypress', 'input[type="number"]', function(e) {
      // Allow: backspace, delete, tab, escape, enter, decimal point
      if ($.inArray(e.keyCode, [46, 8, 9, 27, 13, 110, 190]) !== -1 ||
          // Allow: Ctrl+A, Ctrl+C, Ctrl+V, Ctrl+X
          (e.keyCode === 65 && e.ctrlKey === true) ||
          (e.keyCode === 67 && e.ctrlKey === true) ||
          (e.keyCode === 86 && e.ctrlKey === true) ||
          (e.keyCode === 88 && e.ctrlKey === true) ||
          // Allow: home, end, left, right
          (e.keyCode >= 35 && e.keyCode <= 39)) {
        return;
      }
      // Ensure it's a number
      if ((e.shiftKey || (e.keyCode < 48 || e.keyCode > 57)) &&
          (e.keyCode < 96 || e.keyCode > 105)) {
        e.preventDefault();
      }
    });
  }

  /**
   * Loading Indicator Enhancement
   * Adds better visual feedback during long operations
   */
  function enhanceLoadingIndicators() {
    // Listen for Shiny busy/idle events
    $(document).on('shiny:busy', function(event) {
      // Optional: Add custom loading indicator
      console.log('Application is processing...');
    });

    $(document).on('shiny:idle', function(event) {
      console.log('Application is ready');
    });
  }

  // Initialize all handlers
  initializeCollapsibles();
  initializeFileUploadWarnings();
  initializeSmoothScroll();
  initializeTooltips();
  initializeNumericValidation();
  enhanceLoadingIndicators();

  console.log('PG&E Data Visualizer custom JavaScript loaded');
});

/**
 * Shiny Custom Message Handlers
 * Handles custom messages from server
 */
if (typeof Shiny !== 'undefined') {

  // Handler for showing custom notifications
  Shiny.addCustomMessageHandler('showCustomNotification', function(message) {
    var notification = $('<div>')
      .addClass('alert alert-' + message.type)
      .attr('role', 'alert')
      .html('<strong>' + message.title + '</strong> ' + message.text)
      .appendTo('#notification-container');

    setTimeout(function() {
      notification.fadeOut(function() {
        $(this).remove();
      });
    }, message.duration || 5000);
  });

  // Handler for scrolling to element
  Shiny.addCustomMessageHandler('scrollToElement', function(elementId) {
    var element = $('#' + elementId);
    if (element.length) {
      $('html, body').animate({
        scrollTop: element.offset().top - 100
      }, 500);
    }
  });
}

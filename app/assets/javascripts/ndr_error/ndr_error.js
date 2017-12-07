// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require ndr_ui

jQuery(function() {
  // Backtrace toggling:
  (function() {
    var $toggle = jQuery('#toggle_app_trace_only');

    $toggle.off('click').on('click', function(event) {
      jQuery('.trace-item.stack-only').slideToggle();
    });

    // Toggle on page load (not AJAX etc):
    if (!$toggle.checked) $toggle.click();
  })();

  // Searchfield popover behaviour:
  (function() {
    var $searchField = jQuery('#search_form_container input.search-query');

    // Show search hints.
    $searchField.popover({
      title: '<strong>Filter by keywords</strong>',
      content: ' \
        Separate search terms with [ , ; / ]. \
        <em>Terms with two characters or less are ignored</em>.',
      placement: 'bottom',
      html: true,
      trigger: 'manual'
    });

    // Register multiple occurrence badges.
    jQuery('.badge').tooltip();

    $searchField.keydown(function(event) {
      // <ENTER> will submit the search form.
      if (event.keyCode == 13) {
        this.form.submit();
        return false;
      };
    }).focus(function(event) {
      $searchField.popover('show');
    }).blur(function(event) {
      $searchField.popover('hide');
    });
  })();
});

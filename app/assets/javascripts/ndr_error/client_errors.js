var NdrError = {
  url: function() {
    var origin = window.location.origin;

    // IE doesn't support `location.origin`:
    origin = origin || (
      window.location.protocol + '//' +
      window.location.hostname +
      (window.location.port ? ':' + window.location.port: '')
    );

    // TODO: '/fingerprinting' is configureable, use
    // client_errors_url helper?
    return origin + '/fingerprinting/client_errors';
  },

  notify: function(message, source, lineno, colno, error) {
    jQuery.post(NdrError.url(), {
      'client_error': {
        'message': message,
        'source':  source,
        'lineno':  lineno,
        'colno':   colno,
        'stack':   error && error.stack,
        'window.width':  window.innerWidth,
        'window.height': window.innerHeight,
        'screen.width':  window.screen.width,
        'screen.height': window.screen.height
      }
    })
  }
};

window.onerror = function(message, source, lineno, colno, error) {
  NdrError.notify(message, source, lineno, colno, error);
}

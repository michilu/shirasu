(function() {
  var ws;
  ws = new WebSocket("ws://" + window.location["host"] + "/commandline/ping");
  $(function() {
    ws.onmessage = function(e) {
      $("#debug").prepend(e.data);
    };
  });
}).call(this);

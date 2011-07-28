(function() {
  var ws;
  ws = new WebSocket("ws://" + window.location["host"] + "/stat");
  $(function() {
    ws.onmessage = function(e) {
      $("#stats").prepend(e.data + "<br/>");
    };
  });
}).call(this);

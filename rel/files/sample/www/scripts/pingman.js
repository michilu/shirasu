(function() {
  var bit, route, status, ws;
  ws = void 0;
  route = void 0;
  status = {};
  bit = null;
  $(function() {
    var parseJSON, status_color, ws_open;
    parseJSON = function(e) {
      var json;
      try {
        json = $.parseJSON(e.data);
      } catch (error) {
        if (typeof console !== "undefined" && console !== null) {
          console.error(error, e.data.length, e, bit);
        }
        if (bit != null) {
          bit += e.data;
          try {
            json = $.parseJSON(bit);
          } catch (error) {
            if (typeof console !== "undefined" && console !== null) {
              console.error(error, e.data.length, e, bit);
            }
          }
        } else {
          bit = e.data;
        }
        return;
      }
      bit = null;
      return json;
    };
    status_color = function(ip, packet_loss) {
      var color, element, _i, _len, _ref, _results;
      switch (packet_loss) {
        case 0.0:
          color = "lightgreen";
          break;
        case 100.0:
          color = "gray";
          break;
        default:
          color = "red";
      }
      _ref = $("text:contains('" + ip + "')");
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        element = _ref[_i];
        _results.push($(element).text() === ip ? $(element).attr("fill", color) : void 0);
      }
      return _results;
    };
    ws_open = function() {
      return ws = new WebSocket("ws://" + window.location["host"] + "/commandline/pingman");
    };
    ws_open();
    ws.onmessage = function(e) {
      var ip, json, packet_loss;
      json = parseJSON(e);
      if (!(json != null)) {
        return;
      }
      if (json.type === "traceroute") {
        if (route !== json.data) {
          route = json.data;
          $("#svg").html(route);
          for (ip in status) {
            packet_loss = status[ip];
            status_color(ip, packet_loss[0]);
          }
        }
      } else if (json.type === "ping") {
        ip = json.data.ip;
        packet_loss = json.data.packet_loss;
        if (!(status[ip] != null)) {
          status[ip] = [];
        }
        status[ip].unshift(packet_loss);
        status_color(ip, packet_loss);
      }
    };
    ws.onclose = function(e) {
      return ws_open();
    };
  });
}).call(this);

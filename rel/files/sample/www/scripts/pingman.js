(function() {
  var bit, route, status, ws;
  ws = void 0;
  route = void 0;
  status = {};
  bit = null;
  $(function() {
    var handle_traceroute, parseJSON, response, status_color, ws_open, ws_retry;
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
          color = "#46A546";
          break;
        case 100.0:
          color = "#F89406";
          break;
        default:
          color = "#C43C35";
      }
      _ref = $("text:contains('" + ip + "')");
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        element = _ref[_i];
        _results.push($(element).text() === ip ? $(element).prev("ellipse").attr("fill", color) : void 0);
      }
      return _results;
    };
    handle_traceroute = function(route) {
      var $svg, ip, margin_top, packet_loss, width;
      $("#svg svg").remove();
      $("#svg").append($(route));
      $svg = $("#svg svg");
      width = $svg.attr("width").match(/^[0-9]+/)[0];
      if (width > 500) {
        margin_top = "-172px";
      }
      if (margin_top != null) {
        $svg.css("margin-top", margin_top);
      }
      $("ellipse", $svg).attr("fill", "#BFBFBF");
      for (ip in status) {
        packet_loss = status[ip];
        status_color(ip, packet_loss[0]);
      }
    };
    ws_open = function() {
      ws = new WebSocket("ws://" + window.location["host"] + "/commandline/pingman");
      ws.onmessage = function(e) {
        var $line, $row, $streams, d, element, escaped_data, i, ip, json, limit, now, packet_loss, _i, _len, _ref, _ref2;
        now = new Date();
        escaped_data = $("<div/>").text(e.data).html();
        $line = $("<span/>").text("[" + (now.getHours()) + ":" + (now.getMinutes()) + ":" + (now.getSeconds()) + "." + (now.getMilliseconds()) + "]" + escaped_data);
        $line.css({
          "background-color": "yellow"
        });
        setTimeout(function() {
          $line.css({
            "background-color": ""
          });
        }, 5000);
        $("#stream").prepend($line);
        $streams = $("#stream span");
        limit = 20;
        for (i = limit, _ref = $streams.length - 1; limit <= _ref ? i < _ref : i > _ref; limit <= _ref ? i++ : i--) {
          $($streams[i]).remove();
        }
        json = parseJSON(e);
        if (!(json != null)) {
          return;
        }
        if (json.type === "traceroute") {
          if (route !== json.data) {
            route = json.data;
            handle_traceroute(route);
          }
        } else if (json.type === "ping") {
          ip = json.data.ip;
          packet_loss = json.data.packet_loss;
          if (!(status[ip] != null)) {
            status[ip] = [];
          }
          status[ip].unshift(packet_loss);
          status_color(ip, packet_loss);
          d = json.data;
          if (d.packet_loss < 100) {
            _ref2 = $("td:contains('" + d.ip + "')");
            for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
              element = _ref2[_i];
              if ($(element).text() === d.ip) {
                $(element).parent("tr").remove();
              }
            }
            $row = $("<tr><td>" + ([d.ip, d.packet_loss, d.max, d.avg, d.min, d.stddev].join('</td><td>')) + "</td></tr>").prependTo("table tbody").css({
              "background-color": "yellow"
            });
            setTimeout(function() {
              $row.css({
                "background-color": ""
              });
            }, 5000);
            $("table").trigger("update");
          }
        }
      };
      ws.onclose = function(e) {
        ws_retry();
      };
    };
    ws_open();
    ws_retry = function() {
      var response;
      response = $.ajax({
        url: "",
        async: false
      });
      if (response.status === 200) {
        ws_open();
      } else {
        setTimeout(ws_retry, 5000);
      }
    };
    response = $.ajax({
      url: "/traceroute.svg",
      async: false
    });
    handle_traceroute(response.responseText);
    $("table").tablesorter();
  });
}).call(this);

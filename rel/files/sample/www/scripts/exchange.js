(function() {
  var buffer, chart, count, data, drawVisualization, flag, recieved, stop, ws;
  ws = new WebSocket("ws://" + window.location["host"] + "/exchange/USDJPY");
  count = 70;
  buffer = 300;
  recieved = 0;
  flag = null;
  stop = null;
  chart = null;
  data = [];
  google.load('visualization', '1', {
    packages: ['corechart']
  });
  google.setOnLoadCallback(function() {
    chart = new google.visualization.CandlestickChart(document.getElementById('holder'));
    google.visualization.events.addListener(chart, 'onmouseover', function() {
      return stop = true;
    });
    google.visualization.events.addListener(chart, 'onmouseout', function() {
      return stop = false;
    });
    drawVisualization([["loading...", 100, 100, 100, 100]], 'out');
  });
  drawVisualization = function(raws, hAxis_textPosition) {
    var dataTable;
    dataTable = google.visualization.arrayToDataTable(raws, true);
    chart.draw(dataTable, {
      title: "Exchange Chart via WebSocket: USD/JPY (buffering " + data.length + " data, recieved " + recieved + " data)",
      legend: 'none',
      hAxis: {
        textPosition: hAxis_textPosition != null ? hAxis_textPosition : 'none'
      }
    });
  };
  setInterval(function() {
    if (!stop && data.length >= count) {
      drawVisualization(data.slice(0, count));
      data.shift();
      return flag = false;
    } else {
      return flag = true;
    }
  }, 300);
  $(function() {
    ws.onopen = function() {};
    ws.onmessage = function(e) {
      var i, index, line, rows, _len, _ref;
      recieved += 1;
      if (e.data && flag) {
        line = e.data;
        if (line.charAt(0) === "1") {
          rows = line.split(",").slice(0, 5);
          rows[0] = (new Date(parseInt(rows[0]) * 1000)).toString();
          _ref = rows.slice(1, 5);
          for (index = 0, _len = _ref.length; index < _len; index++) {
            i = _ref[index];
            rows[index + 1] = parseFloat(i);
          }
          data.push(rows);
        }
      }
    };
  });
}).call(this);

(function() {
  var chart, drawVisualization;
  chart = null;
  google.load('visualization', '1', {
    packages: ['corechart']
  });
  google.setOnLoadCallback(function() {
    chart = new google.visualization.CandlestickChart(document.getElementById('holder'));
    drawVisualization([["loading...", 100, 100, 100, 100]], 'out');
  });
  drawVisualization = function(data, hAxis_textPosition) {
    var dataTable;
    dataTable = google.visualization.arrayToDataTable(data, true);
    chart.draw(dataTable, {
      legend: 'none',
      hAxis: {
        textPosition: hAxis_textPosition != null ? hAxis_textPosition : 'none'
      }
    });
  };
  $(function() {
    var data, ws;
    data = [];
    ws = new WebSocket("ws://localhost:8000/exchange/USDJPY");
    ws.onopen = function() {};
    ws.onmessage = function(e) {
      var i, index, line, rows, _len, _ref;
      if (e.data) {
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
      while (data.length > 30) {
        data.shift();
      }
      drawVisualization(data);
    };
  });
}).call(this);

# -*- coding: utf-8 -*-
chart = null
google.load 'visualization', '1',
  packages: ['corechart']
google.setOnLoadCallback () ->
  chart = new google.visualization.CandlestickChart document.getElementById 'holder'
  drawVisualization [["loading...",100,100,100,100]], 'out'
  return
drawVisualization = (data, hAxis_textPosition) ->
  # Populate the data table.
  dataTable = google.visualization.arrayToDataTable data, true
  # Draw the chart.
  chart.draw dataTable,
    legend: 'none'
    hAxis:
      textPosition: hAxis_textPosition ? 'none'
  return

$ () ->
  data = []
  ws = new WebSocket "ws://localhost:8000/exchange/USDJPY"
  ws.onopen = () ->
    #ws.send 'hello'
    return
  ws.onmessage = (e) ->
    #$("#debug").text(e.data)
    if e.data
      line = e.data
      if line.charAt(0) == "1"
        rows = line.split(",")[..4]
        rows[0] = (new Date(parseInt(rows[0]) * 1000)).toString()
        for i ,index in rows[1..4]
          rows[index+1] = parseFloat i
        data.push rows
    while data.length > 30
      data.shift()
    drawVisualization data
    #s.send 'ok'
    return
  return

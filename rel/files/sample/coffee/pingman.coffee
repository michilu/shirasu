# -*- coding: utf-8 -*-
ws = undefined
route = undefined
status = {}
bit = null

$ () ->
  parseJSON = (e) ->
    try
      json = $.parseJSON(e.data)
    catch error
      console?.error error, e.data.length, e, bit
      if bit?
        bit += e.data
        try
          json = $.parseJSON(bit)
        catch error
          console?.error error, e.data.length, e, bit
      else
        bit = e.data
      return
    bit = null
    return json

  status_color = (ip, packet_loss) ->
    switch packet_loss
      when 0.0
        color = "#46A546" #green
      when 100.0
        color = "#F89406" #orange
      else
        color = "#C43C35" #red
    for element in $("text:contains('#{ip}')")
      if $(element).text() == ip
        $(element).prev("ellipse").attr("fill", color)

  handle_traceroute = (route) ->
    $("#svg svg").remove()
    $("#svg").append($(route))
    $svg = $("#svg svg")
    width = $svg.attr("width").match(/^[0-9]+/)[0]
    if width > 500
      margin_top = "-172px"
    if margin_top?
      $svg.css("margin-top", margin_top)
    $("ellipse", $svg).attr("fill", "#BFBFBF") #gray
    for ip, packet_loss of status
      status_color(ip, packet_loss[0])
    return

  ws_open = () ->
    ws = new WebSocket "ws://#{window.location["host"]}/commandline/pingman"
    ws.onmessage = (e) ->
      now = new Date()
      escaped_data = $("<div/>").text(e.data).html()
      $line = $("<span/>").text("[#{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}.#{now.getMilliseconds()}]#{escaped_data}")
      $line.css
        "background-color": "yellow"
      setTimeout () ->
        $line.css
          "background-color": ""
        return
      , 5000
      $("#stream").prepend($line)
      $streams = $("#stream span")
      limit = 20
      for i in [limit...$streams.length-1]
        $($streams[i]).remove()
      json = parseJSON e
      if !json?
        return
      if json.type == "traceroute"
        if route != json.data
          route = json.data
          handle_traceroute route
      else if json.type == "ping"
        ip = json.data.ip
        packet_loss = json.data.packet_loss
        if not status[ip]?
          status[ip] = []
        status[ip].unshift(packet_loss)
        status_color(ip, packet_loss)
        d = json.data
        if d.packet_loss < 100
          for element in $("td:contains('#{d.ip}')")
            if $(element).text() == d.ip
              $(element).parent("tr").remove()
          $row = $("<tr><td>#{[d.ip, d.packet_loss, d.max, d.avg, d.min, d.stddev].join('</td><td>')}</td></tr>")
          .prependTo("table tbody")
          .css
            "background-color": "yellow"
          setTimeout () ->
            $row.css
              "background-color": ""
            return
          , 5000
          $("table")
          .trigger("update")
      return
    ws.onclose = (e) ->
      ws_retry()
      return
    return
  ws_open()

  ws_retry = () ->
    response = $.ajax
      url: ""
      async: false
    if response.status is 200
      ws_open()
    else
      setTimeout ws_retry, 5000
    return

  response = $.ajax
    url: "/traceroute.svg"
    async: false
  handle_traceroute response.responseText
  $("table").tablesorter()
  return

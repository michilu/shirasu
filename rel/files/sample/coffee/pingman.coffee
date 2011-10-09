# -*- coding: utf-8 -*-
# http://wq.apnic.net/apnic-bin/whois.pl?searchtext=72.14.203.103
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
        color = "lightgreen"
      when 100.0
        color = "gray"
      else
        color = "red"
    for element in $("text:contains('#{ip}')")
      if $(element).text() == ip
        $(element).attr("fill", color)

  ws_open = () ->
    ws = new WebSocket "ws://#{window.location["host"]}/commandline/pingman"
  ws_open()

  ws.onmessage = (e) ->
    json = parseJSON e
    if !json?
      return
    if json.type == "traceroute"
      if route != json.data
        route = json.data
        $("#svg").html(route)
        for ip, packet_loss of status
          status_color(ip, packet_loss[0])
    else if json.type == "ping"
      ip = json.data.ip
      packet_loss = json.data.packet_loss
      if not status[ip]?
        status[ip] = []
      status[ip].unshift(packet_loss)
      status_color(ip, packet_loss)
    return

  ws.onclose = (e) ->
    ws_open()

  return

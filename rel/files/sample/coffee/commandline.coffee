# -*- coding: utf-8 -*-
ws = new WebSocket "ws://#{window.location["host"]}/commandline/ping"

$ () ->
  ws.onmessage = (e) ->
    $("#debug").prepend(e.data + "<br/>")
    return
  return

# -*- coding: utf-8 -*-
ws = new WebSocket "ws://#{window.location["host"]}/stat"

$ () ->
  ws.onmessage = (e) ->
    $("#stats").prepend(e.data + "<br/>")
    return
  return

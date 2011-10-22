$ () ->
  escape = (data) ->
    return $("<div/>").text(data).html()
  stream = (d) ->
    now = new Date()
    data = d.data
    if data[data.length-1] isnt "\n"
      data += "\n"
    line = "[#{d.time[0..2].join(':')}.#{d.time[3]}]&nbsp;#{data}"
    $("#stream").prepend(line)
  parse = (e) ->
    now = new Date()
    hours = now.getHours()
    minutes = now.getMinutes()
    seconds = now.getSeconds()
    milliseconds = now.getMilliseconds()
    if hours < 10 then hours = "0#{hours}"
    if minutes < 10 then minutes = "0#{minutes}"
    if seconds < 10 then seconds = "0#{seconds}"
    result =
      data: escape(e.data)
      time: [hours, minutes, seconds, milliseconds]
    return result
  chat =
    connect: () ->
      @._ws = new WebSocket "ws://"+window.location["host"]+"/chat"
      @._ws.onmessage = @._onmessage
      @._ws.onclose = @._onclose
      return
    send: (message) ->
      if message?.length > 0
        @._ws?.send message
      return
    _onmessage: (e) ->
      d = parse(e)
      stream(d)
      $line = $("<p/>").html("#{d.time[0..2].join(':')}&raquo;&nbsp;#{d.data}")
      $("#chat .log").prepend($line)
      return
    _onclose: (e) ->
      @._ws = null
      return
  $("#chat input:submit").click () ->
    $text = $("#chat .text")
    chat.send $text.val()
    $text.val("").focus()
    return
  chat.connect()

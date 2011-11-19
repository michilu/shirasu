$ () ->
  window.Util =
    parse: (e) ->
      now = new Date()
      hours = now.getHours()
      minutes = now.getMinutes()
      seconds = now.getSeconds()
      milliseconds = now.getMilliseconds()
      if hours < 10 then hours = "0#{hours}"
      if minutes < 10 then minutes = "0#{minutes}"
      if seconds < 10 then seconds = "0#{seconds}"
      result =
        data: e.data
        time: [hours, minutes, seconds, milliseconds]
      return result
    stream : (d) ->
      max = 1965
      $stream = $("#stream")
      if $stream.text().length + d.data.length <= max
        $stream.append(d.data)
      else
        data = d.data[(max - $stream.text().length)...d.data.length]
        while true
          if data.length <= max
            break
          data = data[max...data.length]
        $stream.text(data)
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
      d = Util.parse(e)
      Util.stream(d)
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

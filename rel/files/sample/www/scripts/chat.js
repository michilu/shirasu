(function() {
  $(function() {
    var chat;
    window.Util = {
      escape: function(data) {
        return $("<div/>").text(data).html();
      },
      parse: function(e) {
        var hours, milliseconds, minutes, now, result, seconds;
        now = new Date();
        hours = now.getHours();
        minutes = now.getMinutes();
        seconds = now.getSeconds();
        milliseconds = now.getMilliseconds();
        if (hours < 10) {
          hours = "0" + hours;
        }
        if (minutes < 10) {
          minutes = "0" + minutes;
        }
        if (seconds < 10) {
          seconds = "0" + seconds;
        }
        result = {
          data: escape(e.data),
          time: [hours, minutes, seconds, milliseconds]
        };
        return result;
      },
      stream: function(d) {
        var $stream, data, max;
        max = 1965;
        $stream = $("#stream");
        if ($stream.text().length + d.data.length <= max) {
          return $stream.append(d.data);
        } else {
          data = d.data.slice(max - $stream.text().length, d.data.length);
          while (true) {
            if (data.length <= max) {
              break;
            }
            data = data.slice(max, data.length);
          }
          return $stream.text(data);
        }
      }
    };
    chat = {
      connect: function() {
        this._ws = new WebSocket("ws://" + window.location["host"] + "/chat");
        this._ws.onmessage = this._onmessage;
        this._ws.onclose = this._onclose;
      },
      send: function(message) {
        var _ref;
        if ((message != null ? message.length : void 0) > 0) {
          if ((_ref = this._ws) != null) {
            _ref.send(message);
          }
        }
      },
      _onmessage: function(e) {
        var $line, d;
        d = Util.parse(e);
        Util.stream(d);
        $line = $("<p/>").html("" + (d.time.slice(0, 3).join(':')) + "&raquo;&nbsp;" + d.data);
        $("#chat .log").prepend($line);
      },
      _onclose: function(e) {
        this._ws = null;
      }
    };
    $("#chat input:submit").click(function() {
      var $text;
      $text = $("#chat .text");
      chat.send($text.val());
      $text.val("").focus();
    });
    return chat.connect();
  });
}).call(this);

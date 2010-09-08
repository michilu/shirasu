-module(shirasu_http_stream).
-author('Takanao ENDOH <djmchl@gmail.com>').

-export([start/0, stop/0, processing/1]).

start() ->
    _Pid = spawn(twitter_stream, fetch,
                  [bitstring_to_list(shirasu:cfg(["shirasu_http_stream", "url"])),
                   fun(Data) ->
                    wsManager ! {send, Data}
                   end]),
    ok.

stop() ->
    ok.

processing(_Data) ->
    ok.


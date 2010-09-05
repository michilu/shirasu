-module(shirasu).
-author('Takanao ENDOH <djmchl@gmail.com>').
-export([start/0, start/1, stop/0]).

start() ->
    application:start(shirasu).

start(Port) ->
    error_logger:info_msg("shirasu:start~n"),
    Manager = spawn(shirasu_websocket, wsManager, []),
    Options = {},
    _Stock = spawn(stock, start, [Options]),
    _TWStream = spawn(shirasu_http_stream, start, [Options]),
    misultin:start_link([
        {port, Port},
        {loop, fun(Req) ->
                    shirasu_http_serve:handle_http(Req) end},
        {ws_loop, fun(Ws) ->
                    shirasu_websocket:handle_websocket(new, Ws) end},
        {ws_autoexit, false}
    ]).

stop() ->
    wsManager ! stop,
    misultin:stop().


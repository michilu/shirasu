-module(shirasu).
-author('Takanao ENDOH <djmchl@gmail.com>').
-export([start/0, stop/0, boot/0, cfg/1, cfgManager/1]).

start() ->
    application:start(shirasu).

stop() ->
    wsManager ! stop,
    cfgManager ! stop,
    misultin:stop().

boot() ->
    {ok, Path} = application:get_env(shirasu, setting),
    {ok, Cfg} = loadCfg(Path),
    register(cfgManager, spawn(?MODULE, cfgManager, [Cfg])),
    spawn(shirasu_websocket, wsManager, []),
    _Stock = spawn(stock, start, []),
    _TWStream = spawn(shirasu_http_stream, start, []),
    misultin:start_link([
        {port, cfg(["shirasu", "listen", "port"])},
        {loop, fun(Req) ->
                    shirasu_http_serve:handle_http(Req) end},
        {ws_loop, fun(Ws) ->
                    shirasu_websocket:handle_websocket(new, Ws) end},
        {ws_autoexit, false}
    ]).

cfg(Key) ->
    cfgManager ! {self(), get, Key},
    receive
        {ok, Value} ->
            Value
    end.

loadCfg(Path) ->
    Setting =  os:cmd("/usr/bin/env python -c '\
import json, yaml;\
print json.dumps(yaml.load(open(\"" ++ Path ++ "\")));\
'"),
    {ok, Cfg, _} = rfc4627:decode(Setting),
    {ok, Cfg}.

cfgManager(Cfg) ->
    receive
        {Pid, get, Key} ->
            {ok, Value} = get_field(Cfg, Key),
            Pid ! {ok, Value};
        _Any ->
            pass
    end,
    cfgManager(Cfg).

get_field(Value, []) ->
    {ok, Value};
get_field(Json, [Key|KeyList]) ->
    case rfc4627:get_field(Json, Key) of
        {ok, Value} ->
            get_field(Value, KeyList)
    end.


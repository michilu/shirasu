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
    {ok, Config} = loadConfig(Path),
    register(cfgManager, spawn(?MODULE, cfgManager, [Config])),
    Modules = getModules(),
    lists:map(fun(Module) -> register(Module, spawn(Module, start, [])) end, Modules),
    spawn(shirasu_websocket, wsManager, []),
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

loadConfig(Path) ->
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

getModules() ->
    {obj, FieldList} = cfg([]),
    Modules = lists:filter(fun(X) ->
                                case X of
                                    shirasu -> false;
                                    _ -> true
                                end
                           end,
                           lists:map(fun({Key, _Fields}) -> list_to_atom(Key) end, FieldList)),
    Modules.


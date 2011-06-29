-module(shirasu).
-author('Takanao ENDOH <djmchl@gmail.com>').
-export([start/0, stop/0, boot/0, cfg/1, cfgManager/1]).

-include_lib("eunit/include/eunit.hrl").
%?debugVal(PropList),

start() ->
    application:start(shirasu).

stop() ->
    wsManager ! stop,
    cfgManager ! stop,
    misultin:stop().

boot() ->
    {ok, Path} = application:get_env(shirasu, setting),
    {struct, PropList} = loadConfig(Path),
    register(cfgManager, spawn(?MODULE, cfgManager, [PropList])),
    Modules = getModules(),
    ok = inets:start(),
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
    try
      {struct, PropList} = mochijson2:decode(Setting),
      {struct, PropList}
    catch
      throw:invalid_utf8 ->
        {fail, "Invalid JSON: Illegal UTF-8 character"};
      error:Error ->
        {fail, "Invalid JSON: " ++ binary_to_list(list_to_binary(io_lib:format("~p", [Error])))}
    end.

cfgManager(PropList) ->
    receive
        {Pid, get, get_keys} ->
            Term = lists:map(fun(Key) ->
                                list_to_atom(bitstring_to_list(Key))
                             end,
                             proplists:get_keys(PropList)),
            Pid ! {ok, Term};
        {Pid, get, Keys} ->
            KeyList = lists:map(fun(Key) ->
                                    list_to_bitstring(Key)
                                end,
                                Keys),
            {ok, Value} = get_field(PropList, KeyList),
            Pid ! {ok, Value};
        _Any ->
            pass
    end,
    cfgManager(PropList).

get_field(Value, []) ->
    {ok, Value};
get_field(PropList, [Key|KeyList]) ->
    case proplists:get_value(Key, PropList) of
        %undefined -> TODO(ENDOH)
        {struct, Value} ->
            get_field(Value, KeyList);
        Value ->
            get_field(Value, KeyList)
    end.

getModules() ->
    Keys = cfg(get_keys),
    Modules = lists:filter(fun(X) ->
                                case X of
                                    shirasu -> false;
                                    _ -> true
                                end
                           end,
                           Keys),
    Modules.


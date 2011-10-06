-module(shirasu).
-author('ENDOH takanao <djmchl@gmail.com>').
-export([start/0, stop/0, boot/0, cfg/1, cfgManager/1, handle_websocket/2, wsManager/0, hookManager/0]).

-include_lib("eunit/include/eunit.hrl").
%?debugVal(),

start() ->
  application:start(shirasu).

stop() ->
  wsManager ! stop,
  cfgManager ! stop,
  hookManager ! stop,
  misultin:stop().

boot() ->
  {ok, Path} = application:get_env(shirasu, setting),
  {struct, PropList} = loadConfig(Path),
  spawn(?MODULE, hookManager, []),
  register(cfgManager, spawn(?MODULE, cfgManager, [PropList])),
  Modules = getModules(),
  ok = inets:start(),
  lists:map(
    fun(Module) ->
      register(Module, spawn(Module, start, []))
    end,
    Modules),
  spawn(?MODULE, wsManager, []),
  ServerPid = listen_port(cfg(["shirasu"])),
  ServerPid.

listen_port([{struct, PropList}|_T]) ->
  Port = proplists:get_value(<<"port">>, PropList),
  BaseMisultinOptions = [
    {port, Port},
    {loop, fun(Req) ->
            shirasu_http_serve:handle_http(Req)
           end},
    {ws_loop, fun(Ws) ->
                ?MODULE:handle_websocket(new, Ws)
              end},
    {ws_autoexit, false}
  ],
  case proplists:get_value(<<"ssl">>, PropList) of
    {struct, Cert} ->
      MisultinOptions = BaseMisultinOptions ++ [
        {ssl, [
          {certfile, binary_to_list(proplists:get_value(<<"certfile">>, Cert))},
          {keyfile, binary_to_list(proplists:get_value(<<"keyfile">>, Cert))},
          {password, binary_to_list(proplists:get_value(<<"password">>, Cert))}
        ]}],
      case application:get_application(crypto) of
        undefined ->
          ok =  application:start(crypto),
          ok =  application:start(public_key);
        {ok, crypto} ->
          pass
      end;
    undefined ->
      MisultinOptions = BaseMisultinOptions
  end,
  {ok, Pid} =  misultin:start_link(MisultinOptions),
  {ok, Pid}.

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
      Term = lists:map(
              fun(Key) ->
                list_to_atom(bitstring_to_list(Key))
              end,
              proplists:get_keys(PropList)),
      Pid ! {ok, Term};
    {Pid, get, Keys} ->
      KeyList = lists:map(
                  fun(Key) ->
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
  Modules = lists:filter(
              fun(X) ->
                case X of
                  shirasu -> false;
                  _ -> true
                end
              end,
              Keys),
  Modules.

handle_websocket(Ws) ->
  receive
      {browser, Data} ->
          %?debugVal({"ws:browser", Data}),
          hookManager ! {Ws:get(path), Data, self()},
          handle_websocket(Ws);
      closed ->
          wsManager ! {del, Ws:get(path), self()},
          %?debugVal("ws:close"),
          exit(self(), kill);
      {send, Data} ->
          %?debugVal({"ws:send", Data}),
          Ws:send(Data),
          handle_websocket(Ws);
      _Ignore ->
          handle_websocket(Ws)
  after 5000 ->
      %Ws:send(["pushing!"]),
      handle_websocket(Ws)
  end.

handle_websocket(new, Ws) ->
  %?debugVal({"handle_websocket:new:", Ws:get(path)}),
  wsManager ! {add, Ws:get(path), self()},
  handle_websocket(Ws).

wsManager() ->
  register(wsManager, self()),
  process_flag(trap_exit, true),
  wsManager([]).
wsManager(ChannelList) ->
  receive
    {add, Channel, Pid} ->
      %?debugVal({add, Channel, Pid}),
      case lists:keysearch(Channel, 1, ChannelList) of
        {value, {Channel, PidList}} ->
          case lists:member(Pid, PidList) of
            true ->
              wsManager(ChannelList);
            false ->
              NewPidList = lists:append([Pid], PidList),
              NewChannelList = lists:keyreplace(Channel, 1, ChannelList, {Channel, NewPidList}),
              %?debugVal(NewChannelList),
              wsManager(NewChannelList)
          end;
        false ->
          wsManager(lists:append([{Channel, [Pid]}], ChannelList))
      end;
    {del, Channel, Pid} ->
      %?debugVal({del, Channel, Pid}),
      case lists:keysearch(Channel, 1, ChannelList) of
        {value, {Channel, PidList}} ->
          case lists:member(Pid, PidList) of
            true ->
              NewPidList = lists:delete(Pid, PidList),
              NewChannelList = lists:keyreplace(Channel, 1, ChannelList, {Channel, NewPidList}),
              %?debugVal(NewChannelList),
              wsManager(NewChannelList);
            false ->
              wsManager(ChannelList)
          end;
        false ->
          wsManager(ChannelList)
      end;
    {get, Channel, Pid} ->
      %?debugVal({get, Channel, Pid}),
      case lists:keysearch(Channel, 1, ChannelList) of
        {value, {Channel, PidList}} ->
          Pid ! PidList;
        false ->
          Pid ! false
      end,
      wsManager(ChannelList);
    {send, Channel, Data} ->
      case lists:keysearch(Channel, 1, ChannelList) of
        {value, {_Channel, PidList}} ->
          %?debugVal(io:format("~p", [{Channel, PidList, Data}])),
          lists:map(
            fun(PID) ->
              PID ! {send, Data}
            end,
            PidList);
        false ->
          pass
      end,
      wsManager(ChannelList);
    {stat, Pid} ->
      Pid ! {stat, ChannelList},
      wsManager(ChannelList);
    stop ->
      exit(normal);
    Any ->
      ?debugVal(Any)
  end.

hookManager() ->
  register(hookManager, self()),
  process_flag(trap_exit, true),
  hookManager([]).
hookManager(Hooks) ->
  receive
    {add} ->
      pass;
    {del} ->
      pass;
    {Path, Data, _Pid} ->
      wsManager ! {send, Path, Data},
      pass;
    stop ->
      exit(normal);
    Any ->
      ?debugVal(Any)
  end,
  hookManager(Hooks).

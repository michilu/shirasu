-module(shirasu_websocket).
-author('Takanao ENDOH <djmchl@gmail.com>').
-export([handle_websocket/2, wsManager/0]).

-include_lib("eunit/include/eunit.hrl").

handle_websocket(Ws) ->
    receive
            {browser, Data} ->
                    %?debugVal({"ws:browser", Data}),
                    wsManager ! {send, Ws:get(path), Data},
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
            %?debugVal({send, Channel, Data}),
            case lists:keysearch(Channel, 1, ChannelList) of
                {value, {_Channel, PidList}} ->
                    lists:map(fun(PID) -> PID ! {send, Data} end, PidList);
                false ->
                    pass
            end,
            wsManager(ChannelList);
        stop ->
            exit(normal);
        Any ->
            error_logger:info_msg("wsManager:receive:Any:~p~n", [Any])
    end.

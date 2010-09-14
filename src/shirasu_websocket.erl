-module(shirasu_websocket).
-author('Takanao ENDOH <djmchl@gmail.com>').
-export([handle_websocket/2, wsManager/0]).

handle_websocket(Ws) ->
    receive
            {browser, Data} ->
                    Ws:send(["received '", Data, "'"]),
                    handle_websocket(Ws);
            closed ->
                    wsManager ! {del, Ws:get(path), self()},
                    error_logger:info_msg("~p~n", ["ws:close"]),
                    exit(self(), kill);
            {send, Data} ->
                    %error_logger:info_msg("~p~n", [{"ws:send", Data}]),
                    Ws:send(Data),
                    handle_websocket(Ws);
            _Ignore ->
                    handle_websocket(Ws)
    after 5000 ->
            %Ws:send(["pushing!"]),
            handle_websocket(Ws)
    end.

handle_websocket(new, Ws) ->
    %error_logger:info_msg("~p~n", [{"handle_websocket:new:", Ws:get(path)}]),
    wsManager ! {add, Ws:get(path), self()},
    handle_websocket(Ws).

wsManager() ->
    register(wsManager, self()),
    process_flag(trap_exit, true),
    wsManager([]).
wsManager(ChannelList) ->
    receive
        {add, Channel, Pid} ->
            %error_logger:info_msg("wsManager:receive:~p~n", [{add, Channel, Pid}]),
            case lists:keysearch(Channel, 1, ChannelList) of
                {value, {Channel, PidList}} ->
                    case lists:member(Pid, PidList) of
                        true ->
                            wsManager(ChannelList);
                        false ->
                            NewPidList = [Pid] ++ PidList,
                            %error_logger:info_msg("wsManager:PidList:~p~n", [NewPidList]),
                            wsManager(lists:keyreplace(Channel, 1, ChannelList, NewPidList))
                    end;
                false ->
                    wsManager(lists:append([{Channel, [Pid]}], ChannelList))
            end;
        {del, Channel, Pid} ->
            %error_logger:info_msg("wsManager:receive:~p~n", [{del, Channel, Pid}]),
            case lists:keysearch(Channel, 1, ChannelList) of
                {value, {Channel, PidList}} ->
                    case lists:member(Pid, PidList) of
                        true ->
                            NewPidList = lists:delete(Pid, PidList),
                            %error_logger:info_msg("wsManager:PidList:~p~n", [NewPidList]),
                            wsManager(lists:keyreplace(Channel, 1, ChannelList, NewPidList));
                        false ->
                            wsManager(ChannelList)
                    end;
                false ->
                    wsManager(ChannelList)
            end;
        {get, Channel, Pid} ->
            %error_logger:info_msg("wsManager:receive:~p~n", [{get, Channel, Pid}]),
            case lists:keysearch(Channel, 1, ChannelList) of
                {value, {Channel, PidList}} ->
                    Pid ! PidList;
                false ->
                    Pid ! false
            end,
            wsManager(ChannelList);
        {send, Channel, Data} ->
            %error_logger:info_msg("wsManager:receive:~p~n", [{send, Channel, Data}]),
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


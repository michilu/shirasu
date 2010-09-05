-module(shirasu_websocket).
-author('Takanao ENDOH <djmchl@gmail.com>').
-export([handle_websocket/2, wsManager/0]).

handle_websocket(Ws) ->
    receive
            {browser, Data} ->
                    Ws:send(["received '", Data, "'"]),
                    handle_websocket(Ws);
            closed ->
                    wsManager ! {del, self()},
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
    wsManager ! {add, self()},
    handle_websocket(Ws).

wsManager() ->
    register(wsManager, self()),
    process_flag(trap_exit, true),
    wsManager([]).
wsManager(PidList) ->
    receive
        {add, Pid} ->
            case lists:member(Pid, PidList) of
                true ->
                    wsManager(PidList);
                false ->
                    PidList1 = [Pid] ++ PidList,
                    error_logger:info_msg("wsManager:PidList:~p~n", [PidList1]),
                    wsManager(PidList1)
            end;
        {del, Pid} ->
            PidList1 = lists:delete(Pid, PidList),
            error_logger:info_msg("wsManager:PidList:~p~n", [PidList1]),
            wsManager(PidList1);
        {get, Pid} ->
            Pid ! PidList,
            wsManager(PidList);
        {send, Data} ->
            %error_logger:info_msg("wsManager:send:~p~n", [Data]),
            lists:map(fun(PID) -> PID ! {send, Data} end, PidList),
            wsManager(PidList);
        stop ->
            exit(normal)
    end.


-module(shirasu_proxy_commandline).
-author('ENDOH takanao <djmchl@gmail.com>').
-export([start/0, command_handler/2]).

-include_lib("eunit/include/eunit.hrl").
%?debugVal(),

start() ->
  CfgList = shirasu:cfg(["shirasu_proxy_commandline"]),
  [{Path, Cmd}|_T] = CfgList,
  spawn(?MODULE, command_handler, [binary_to_list(Cmd), {binary_to_list(Path)}]),
  ok.

command_handler(Cmd, Opt) ->
  Port = open_port({spawn, Cmd}, [stream, use_stdio, exit_status]),
  receive_command_response(Port, Opt).

receive_command_response(Port, {Path}) ->
  receive
    {Port, {data, Data}} ->
      lists:map(fun(Line) ->
                  case Line of
                    [] ->
                      pass;
                    _ ->
                      %?debugVal(io:format("~p", [{Path, Line}])),
                      wsManager ! {send, Path, Line}
                  end
                end, string:tokens(Data, "\r\n"));
    {Port, {exit_status, Status}} ->
      ?debugVal(io:format("~p", [{Port, {exit_status, Status}}])),
      pass;
    Any ->
      ?debugVal(io:format("~p", [Any])),
      pass
  end,
  receive_command_response(Port, {Path}).

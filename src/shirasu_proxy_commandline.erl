-module(shirasu_proxy_commandline).
-author('ENDOH takanao <djmchl@gmail.com>').
-export([start/0, commands/2]).

-include_lib("eunit/include/eunit.hrl").
%?debugVal(),

start() ->
  CfgList = shirasu:cfg(["shirasu_proxy_commandline"]),
  [{Path, Cmd}|_T] = CfgList,
  Opt = {binary_to_list(Path)},
  spawn(?MODULE, commands, [Cmd, Opt]),
  ok.

commands(Cmd, Opt) when is_bitstring(Cmd) ->
  command_handler(binary_to_list(Cmd), Opt),
  ok;
commands(Cmds, Opt) ->
  lists:map(fun(Cmd) ->
              command_handler(binary_to_list(Cmd), Opt)
            end,
            Cmds),
  commands(Cmds, Opt).

command_handler(Cmd, Opt) ->
  Port = open_port({spawn, Cmd}, [stream, exit_status, stderr_to_stdout]),
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
                end, string:tokens(Data, "\r\n")),
      receive_command_response(Port, {Path});
    {Port, {exit_status, _Status}} ->
      pass;
    Any ->
      ?debugVal(io:format("~p", [Any])),
      pass
  end,
  ok.

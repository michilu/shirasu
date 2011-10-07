-module(shirasu_commandline).
-author('ENDOH takanao <djmchl@gmail.com>').

-export([start/0, commands/3, command_handler/3]).

-behaviour(gen_event).
-export([init/1, handle_event/2, handle_call/2, handle_info/2, terminate/2, code_change/3, format_status/2]).

-include_lib("eunit/include/eunit.hrl").
%?debugVal(),

start() ->
  CfgList = shirasu:cfg(["shirasu_commandline"]),
  lists:map(
    fun({Path, Cmds}) ->
      Args = [Cmds, binary_to_list(Path), undefined],
      spawn(?MODULE, commands, Args)
    end,
    CfgList),
  ok.

commands(Cmd, Path, _Pid) when is_bitstring(Cmd) ->
  gen_event:add_handler(shirasu_hooks, ?MODULE, [{binary_to_list(Cmd), Path}]),
  %TODO(endoh): already
  ok;
commands(Cmds, Path, Pid) ->
  lists:map(
    fun(Cmd) ->
      command_handler(binary_to_list(Cmd), Path, Pid)
    end,
    Cmds),
  commands(Cmds, Path, Pid).

command_handler(Cmd, Path, Pid) ->
  Port = open_port({spawn, Cmd}, [stream, exit_status, stderr_to_stdout]),
  receive_command_response(Port, Path, Pid).

receive_command_response(Port, Path, Pid) ->
  receive
    {Port, {data, Data}} ->
      lists:map(
        fun(Line) ->
          case Line of
            [] ->
              pass;
            _ ->
              case Pid of
                undefined ->
                  wsManager ! {send, Path, Line};
                Pid ->
                  Pid ! {send, Line}
              end
          end
        end,
        string:tokens(Data, "\r\n")),
      receive_command_response(Port, Path, Pid);
    {Port, {exit_status, _Status}} ->
      pass;
    Any ->
      ?debugVal(io:format("~p", [Any])),
      pass
  end,
  ok.

init(InitArg) ->
  State = InitArg,
  {ok, State}.

handle_event(Event, State) ->
  [{Cmd, Path}] = State,
  case Event of
    {add, Path, Pid} ->
      spawn(?MODULE, command_handler, [Cmd, undefined, Pid]);
    _ ->
      pass
  end,
  NewState = State,
  Result = {ok, NewState},
  Result.

handle_call(Request, State) ->
  Reply = Request,
  NewState = State,
  Result = {ok, Reply, NewState},
  Result.

handle_info(_Info, State) ->
  NewState = State,
  Result = {ok, NewState},
  Result.

terminate(Arg, _State) ->
  case Arg of
    {stop, _Reason} ->
      pass;
    stop ->
      pass;
    remove_handler ->
      pass;
    {error, {'EXIT', _Reason}} ->
      pass;
    {error, _Term} ->
      pass;
    _Args ->
      pass
  end.

code_change(_OldVsn, State, _Extra) ->
  NewState = State,
  {ok, NewState}.

format_status(_Opt, [_PDict, _State]) ->
  Status = ok,
  Status.

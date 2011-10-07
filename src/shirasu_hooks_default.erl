-module(shirasu_hooks_default).
-author('ENDOH takanao <djmchl@gmail.com>').

-behaviour(gen_event).
-export([init/1, handle_event/2, handle_call/2, handle_info/2, terminate/2, code_change/3, format_status/2]).

-include_lib("eunit/include/eunit.hrl").

init(InitArg) ->
  State = InitArg,
  {ok, State}.

handle_event(Event, State) ->
  {Path, Data, _Pid} = Event,
  wsManager ! {send, Path, Data},
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

-module(shirasu_stat).
-author('ENDOH takanao <djmchl@gmail.com>').

-export([start/0, stop/0, stat/1]).

-include_lib("eunit/include/eunit.hrl").

start() ->
  lists:foreach(fun({Channel, _Bool}) ->
            case is_bitstring(Channel) of
              true ->
                Channel_ = bitstring_to_list(Channel);
              false ->
                Channel_ = Channel
            end,
            statResister({Channel_, spawn(?MODULE, stat, [Channel_])})
          end,
          getChannels()),
  ok.

stop() ->
  lists:foreach(fun({Channel, _Bool}) ->
            case is_bitstring(Channel) of
              true ->
                Channel_ = bitstring_to_list(Channel);
              false ->
                Channel_ = Channel
            end,
            wsManager ! {del, Channel_, self()}
          end,
          getChannels()),
  ok.

getChannels() ->
  lists:filter(fun({_Channel, Bool}) -> Bool end, shirasu:cfg(["shirasu_stat"])).

stat(Channel) ->
  receive
    {stat, ChannelList} ->
      Enc = mochijson2:encoder([{handler, fun(Obj) -> handler(Obj) end}]),
      wsManager ! {send, Channel, Enc(ChannelList)};
    _Ignore ->
      pass
  after 1000 ->
    wsManager ! {stat, self()}
  end,
  stat(Channel).

statResister({Channel, Pid}) ->
  case whereis(wsManager) of
    undefined ->
      timer:sleep(50),
      statResister({Channel, Pid});
    _Any ->
      wsManager ! {add, Channel, Pid}
  end.

handler(Obj) ->
  case is_pid(Obj) of
    true ->
      [String] = io_lib:format("~p", [Obj]),
      list_to_bitstring(String);
    _Any ->
      Obj
  end.

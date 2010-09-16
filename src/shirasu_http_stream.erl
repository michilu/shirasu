-module(shirasu_http_stream).
-author('Takanao ENDOH <djmchl@gmail.com>').

-export([start/0, stop/0, processing/1, fetch/2]).

start() ->
    {obj, CfgList} = shirasu:cfg(["shirasu_http_stream"]),
    lists:foreach(fun({Channel, Url}) ->
                      Fun = fun(Data) ->
                                %error_logger:info_msg("~p~n", [{shirasu_http_stream, twitter_stream, Channel, Data}]),
                                wsManager ! {send, Channel, Data}
                            end,
                      case is_bitstring(Url) of
                          true ->
                              _Pid = spawn(twitter_stream, fetch, [bitstring_to_list(Url), Fun]);
                          false ->
                              _Pid = spawn(?MODULE, fetch, [Url, Fun])
                      end
                  end,
                  CfgList),
    ok.

stop() ->
    ok.

processing(_Data) ->
    ok.

fetch([H|T], Fun) ->
    %error_logger:info_msg("~p~n", [{shirasu_http_stream, fetch, H, T}]),
    twitter_stream:fetch(bitstring_to_list(H), Fun),
    fetch(T ++ [H], Fun).


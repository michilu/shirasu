-module(shirasu_http_stream).
-author('Takanao ENDOH <djmchl@gmail.com>').

-export([start/0, stop/0, processing/1]).

start() ->
    {obj, CfgList} = shirasu:cfg(["shirasu_http_stream"]),
    lists:foreach(fun({Channel, Url}) ->
                      _Pid = spawn(twitter_stream, fetch,
                                   [bitstring_to_list(Url),
                                    fun(Data) ->
                                        %error_logger:info_msg("~p~n", [{shirasu_http_stream, twitter_stream, Channel, Data}]),
                                        wsManager ! {send, Channel, Data}
                                    end])
                  end,
                  CfgList),
    ok.

stop() ->
    ok.

processing(_Data) ->
    ok.


-module(shirasu_http_stream).
-author('Takanao ENDOH <djmchl@gmail.com>').

-export([start/0, stop/0, processing/1, fetch/2, buffer/0]).

start() ->
    CfgList = shirasu:cfg(["shirasu_http_stream"]),
    Buffer = spawn(?MODULE, buffer, []),
    lists:foreach(fun({Channel, Url}) ->
                      Fun = fun(Data) ->
                                %error_logger:info_msg("~p~n", [{shirasu_http_stream, twitter_stream, Channel, Data}]),
                                Buffer ! {Channel, Data}
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

buffer() ->
    buffer([]).

buffer(BufferList) ->
    receive
        {Channel, Data} ->
            case lists:keysearch(Channel, 1, BufferList) of
                {value, {Channel, Buffer}} ->
                    NewBuffer = Buffer ++ bitstring_to_list(Data),
                    [Bits|Lines] = lists:reverse(splitlines(NewBuffer)),
                    NewBufferList = lists:keyreplace(Channel, 1, BufferList, {Channel, Bits});
                false ->
                    NewBuffer = bitstring_to_list(Data),
                    [Bits|Lines] = lists:reverse(splitlines(NewBuffer)),
                    NewBufferList = lists:append([{Channel, Bits}], BufferList)
            end,
            lists:map(fun(Line) ->
                          %error_logger:info_msg("~p~n", [{shirasu_http_stream, buffer, Line}]),
                          wsManager ! {send, Channel, Line}
                      end,
                      lists:reverse(Lines));
        _Any ->
            NewBufferList = BufferList,
            pass
    end,
    buffer(NewBufferList).

splitlines(String) ->
    {match, Matches} = regexp:matches(String, "\n"),
    splitlines(String, [], 1, Matches).

splitlines(String, Parts, Index, []) ->
    lists:reverse([string:substr(String, Index)] ++ Parts);
splitlines(String, Parts, Index, [{NextPt, PtLen}|Matches]) ->
    splitlines(String,
               [string:substr(String, Index, NextPt + PtLen - Index)] ++ Parts,
               NextPt + PtLen,
               Matches).


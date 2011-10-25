-module(twitter_stream).
-author('jebu@jebu.net').
-author('ENDOH takanao <djmchl@gmail.com>').
%% Origin: http://blog.jebu.net/2009/09/erlang-tap-to-the-twitter-stream/
%% 
%% Copyright (c) 2009, Jebu Ittiachen
%% All rights reserved.
%% 
%% Redistribution and use in source and binary forms, with or without modification, are
%% permitted provided that the following conditions are met:
%% 
%%    1. Redistributions of source code must retain the above copyright notice, this list of
%%       conditions and the following disclaimer.
%% 
%%    2. Redistributions in binary form must reproduce the above copyright notice, this list
%%       of conditions and the following disclaimer in the documentation and/or other materials
%%       provided with the distribution.
%% 
%% THIS SOFTWARE IS PROVIDED BY JEBU ITTIACHEN ``AS IS'' AND ANY EXPRESS OR IMPLIED
%% WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
%% FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JEBU ITTIACHEN OR
%% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
%% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
%% ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
%% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
%% ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%% 
%% The views and conclusions contained in the software and documentation are those of the
%% authors and should not be interpreted as representing official policies, either expressed
%% or implied, of Jebu Ittiachen.
%%
%% API
-export([fetch/1, fetch/2, fetch/4, process_data/2]).
 
fetch(URL) ->
  fetch(URL, fun(Data) ->
              error_logger:info_msg("Received tweet ~p ~n", [Data])
             end).

% single arg version expects url of the form http://user:password@stream.twitter.com/1/statuses/sample.json
% this will spawn the 3 arg version so the shell is free
fetch(URL, Callback) ->
  fetch(URL, Callback, 5, 30).
 
% 3 arg version expects url of the form http://user:password@stream.twitter.com/1/statuses/sample.json  
% retry - number of times the stream is reconnected
% sleep - secs to sleep between retries.
fetch(URL, Callback, Retry, Sleep) when Retry > 0 ->
  % setup the request to process async
  % and have it stream the data back to this process
  lists:map(fun(Atom) ->
              case application:get_application(Atom) of
                undefined ->
                  ok = application:start(Atom);
                {ok, Atom} ->
                  pass
              end
            end,
            [crypto, public_key, ssl]),
  try http:request(get, 
                    {URL, []},
                    [{ssl,[{verify,0}]}],
                    [{sync, false}, 
                     {stream, self}]) of
    {ok, RequestId} ->
      case receive_chunk(RequestId, Callback) of
        {ok, _} ->
          % stream broke normally retry 
          timer:sleep(Sleep * 1000),
          fetch(URL, Callback, Retry - 1, Sleep);
        {error, unauthorized, Result} ->
          {error, Result, unauthorized};
        {error, timeout} ->
          timer:sleep(Sleep * 1000),
          fetch(URL, Callback, Retry - 1, Sleep);
        {_, Reason} ->
          error_logger:info_msg("Got some Reason ~p ~n", [Reason]),
          timer:sleep(Sleep * 1000),
          fetch(URL, Callback, Retry - 1, Sleep)
      end;
    _ ->
      timer:sleep(Sleep * 1000),
      fetch(URL, Callback, Retry - 1, Sleep)
  catch 
    _:_ -> 
      timer:sleep(Sleep * 1000),
      fetch(URL, Callback, Retry - 1, Sleep)
  end;
%
fetch(_, _, Retry, _) when Retry =< 0 ->
  error_logger:info_msg("No more retries done with processing fetch thread~n"),
  {error, no_more_retry}.
%
% this is the tweet handler persumably you could do something useful here
%
process_data(Fun, Data) ->
  Fun(Data),
  ok.
 
%%====================================================================
%% Internal functions
%%====================================================================
receive_chunk(RequestId, Callback) ->
  receive
    {http, {RequestId, {error, Reason}}} when(Reason =:= etimedout) orelse(Reason =:= timeout) -> 
      {error, timeout};
    {http, {RequestId, {{_, 401, _} = Status, Headers, _}}} -> 
      {error, unauthorized, {Status, Headers}};
    {http, {RequestId, Result}} -> 
      {error, Result};
 
    %% start of streaming data
    {http,{RequestId, stream_start, Headers}} ->
      error_logger:info_msg("Streaming data start ~p ~n",[Headers]),
      receive_chunk(RequestId, Callback);
 
    %% streaming chunk of data
    %% this is where we will be looping around, 
    %% we spawn this off to a seperate process as soon as we get the chunk and go back to receiving the tweets
    {http,{RequestId, stream, Data}} ->
      spawn(?MODULE, process_data, [Callback, Data]),
      receive_chunk(RequestId, Callback);
 
    %% end of streaming data
    {http,{RequestId, stream_end, Headers}} ->
      error_logger:info_msg("Streaming data end ~p ~n", [Headers]),
      {ok, RequestId}
 
  %% timeout
  after 60 * 1000 ->
    {error, timeout}
  end.

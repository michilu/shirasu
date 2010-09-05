-module(shirasu_app).
-author('Takanao ENDOH <djmchl@gmail.com>').

-behaviour(application).
-export([start/2,stop/1]).

start(_Type, _StartArgs) ->
    shirasu_sup:start_link().

stop(_State) ->
    ok.


-module(shirasu_app).
-author('ENDOH takanao <djmchl@gmail.com>').

-behaviour(application).

%% Application callbacks
-export([start/2,stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    shirasu_sup:start_link().

stop(_State) ->
    ok.

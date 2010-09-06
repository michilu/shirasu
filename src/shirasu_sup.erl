-module(shirasu_sup).
-author('Takanao ENDOH <djmchl@gmail.com>').

-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Server = {shirasu,
                {shirasu, boot, []},
                permanent, 5000, worker, dynamic},

    Processes = [Server],
    {ok, {{one_for_one, 10, 10}, Processes}}.


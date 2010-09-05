-module(shirasu_sup).
-author('Takanao ENDOH <djmchl@gmail.com>').

-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Setting =  os:cmd("/usr/bin/env python -c '\
import json, yaml;\
print yaml.load(open(\"priv/setting.yaml\"))[\"shirasu\"][\"listen\"][\"port\"];\
'"),
    %error_logger:info_msg("~p~n", [Setting]),
    {Int, _Rest} = string:to_integer(Setting),
    Config = [Int],
    Server = {shirasu,
                 {shirasu, start, Config},
                 permanent, 5000, worker, dynamic},

    Processes = [Server],
    {ok, {{one_for_one, 10, 10}, Processes}}.


-module(shirasu_sup).
-author('ENDOH takanao <djmchl@gmail.com>').

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
  error_logger:tty(false),
  error_logger:add_report_handler(erlsyslog, {0, "localhost", 514}),
  Hooks = {shirasu_hooks,
           {gen_event, start_link, [{local, shirasu_hooks}]},
           permanent, 5000, worker, dynamic},
  Server = {shirasu,
            {shirasu, boot, []},
            permanent, 5000, worker, dynamic},

  Processes = [Hooks, Server],
  {ok, {{one_for_one, 10, 10}, Processes}}.

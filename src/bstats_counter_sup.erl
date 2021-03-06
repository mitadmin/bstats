-module(bstats_counter_sup).

-behaviour(supervisor).

-include("bstats.hrl").

%% API
-export([
        start_link/0,
        start_server/2,
        get_counters/0,
        del_all_counters/0,
        disable_counter/2,
        enable_counter/2
    ]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% =============================================================================
%% API functions
%% =============================================================================
-spec start_link() -> {ok, pid()} | ignore | {error, term()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec start_server(atom(), atom()) -> {ok, pid()} | {error, term()}.
start_server(Namespace, Counter) ->
    supervisor:start_child(?MODULE, [Namespace, Counter]).

get_counters() ->
    lists:map(fun({_, Pid, _, _}) ->
                {value, {namespace, Namespace}} = lists:keysearch(namespace, 1, gen_server:call(Pid, get_info)),
                {value, {counter, Counter}} = lists:keysearch(counter, 1, gen_server:call(Pid, get_info)),
                {Namespace, Counter}
        end, supervisor:which_children(?MODULE)).

del_all_counters() ->
    lists:foreach(fun({Namespace, Counter}) ->
                bstats:del_counter(Namespace, Counter)
        end, get_counters()).

disable_counter(Namespace, Counter) ->
    gen_server:call(?COUNTER_SERVER_NAME(Namespace, Counter), disable_counter).

enable_counter(Namespace, Counter) ->
    gen_server:call(?COUNTER_SERVER_NAME(Namespace, Counter), enable_counter).

%% =============================================================================
%% Supervisor callbacks
%% =============================================================================
-spec init(list()) -> {ok, term()}.
init([]) ->
    Bstats = {bstats, {bstats_counter_server, start_link, []},
                          transient, 30000, worker, [bstats]},

    {ok, {{simple_one_for_one, 3, 1}, [Bstats]}}.

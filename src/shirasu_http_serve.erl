-module(shirasu_http_serve).
-author('Takanao ENDOH <djmchl@gmail.com>').
-export([start/0, handle_http/1]).

start() ->
    ok.

handle_http(Req) ->
    {abs_path, Path} = Req:get(uri),
    case [lists:last(Path)] of
        "/" ->
            Path1 = Path ++ "index.html";
        _ ->
            Path1 = Path
    end,
    Req:file("priv/sample/www" ++ Path1).

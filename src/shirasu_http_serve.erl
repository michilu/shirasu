-module(shirasu_http_serve).
-author('ENDOH takanao <djmchl@gmail.com>').
-export([start/0, handle_http/1]).

start() ->
  ok.

handle_http(Req) ->
  Root = bitstring_to_list(shirasu:cfg(["shirasu_http_serve", "/"])),
  {abs_path, Path} = Req:get(uri),
  Req:file(Root ++ Path).

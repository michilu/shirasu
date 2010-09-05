{application, shirasu,
 [{description, "shirasu"},
  {vsn, "0.01"},
  {modules, [
    shirasu,
    shirasu_app,
    shirasu_sup
  ]},
  {registered, []},
  {mod, {shirasu_app, []}},
  {env, []},
  {applications, [kernel, stdlib]}]}.


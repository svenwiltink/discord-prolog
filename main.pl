:- [discord].

custom_handler(_, "MESSAGE_CREATE", Data):-
    format("Custom handler received message create: ~p\n", [Data]).

custom_handler(_, "GUILD_CREATE", Data):-
    format("Custom handler received guild create: ~p\n", [Data]).

:-
    client_create(Client),
    client_add_handler(Client, custom_handler, ClientWithHandler),
    client_run(ClientWithHandler).
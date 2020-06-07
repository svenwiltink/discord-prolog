:- [discord].

custom_handler(_, "MESSAGE_CREATE", Data):-
    format("Custom handler received message create: ~p\n", [Data]).

bot_token(Token):-
    getenv("DISCORDPL_TOKEN", Token).

:-
    bot_token(Token),
    discord_client_create(Token, Client),
    discord_client_add_handler(Client, custom_handler, ClientWithHandler),
    discord_client_run(ClientWithHandler).
:- [discord].
:- use_module(library(http/http_client)).

custom_handler(Client, "MESSAGE_CREATE", Message):-
    \+ get_dict(bot, Message.author, true),
    format("Custom handler received message create: ~p\n", [Message]),
    handle_command(Client, Message).

handle_command(Client, Message):-
    normalize_space(atom(Command), Message.content),
    sub_string(Command, 0, _, 0, "!prolog ping"),
    discord_message_create(Client, Message.channel_id, "PONG", Response),
    format("sent pong: ~p", Response).

bot_token(Token):-
    getenv("DISCORDPL_TOKEN", Token).

:-
    bot_token(Token),
    discord_client_create(Token, Client),
    discord_client_add_handler(Client, custom_handler, ClientWithHandler),
    discord_client_run(ClientWithHandler),
    halt.
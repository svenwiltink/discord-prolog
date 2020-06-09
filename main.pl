:- [discord].
:- use_module(library(http/http_client)).

command_prefix("!prolog").
baas_endpoint("https://butts.ndumas.com").

bot_token(Token):-
    getenv("DISCORDPL_TOKEN", Token).

get_butt(Butt):-
    baas_endpoint(Endpoint),
    http_get(Endpoint, Butt, []).

custom_handler(Client, "MESSAGE_CREATE", Message):-
    \+ get_dict(bot, Message.author, true),
    format("Custom handler received message create: ~p\n", [Message]),
    handle_command(Client, Message).

handle_command(Client, Message):-
    normalize_space(atom(Command), Message.content),
    command_prefix(Prefix),
    sub_string(Command, 0, _, _, Prefix),
    split_string(Command, " ", [], [_|Subcommands]),
    handle_subcommand(Client, Message, Subcommands).

handle_subcommand(Client, Message, ["ping"|[]]):-
    discord_message_create(Client, Message.channel_id, "PONG", _).

handle_subcommand(Client, Message, ["butt"|[]]):-
    get_butt(Butt),
    format(atom(ButtString), "```\n~w\n```", [Butt]),
    discord_message_create(Client, Message.channel_id, ButtString, _).

:-
    bot_token(Token),
    discord_client_create(Token, Client),
    discord_client_add_handler(Client, custom_handler, ClientWithHandler),
    discord_client_run(ClientWithHandler),
    halt.
:- use_module(library(http/websocket)).
:- use_module(library(http/json)).

bot_token(Token):-
    getenv("DISCORDPL_TOKEN", Token).

gateway_url("wss://gateway.discord.gg/?v=6&encoding=json").

send_heartbeat(WS):-
    format("sending heartbeat\n"),
    atom_json_term(Data, json([op=1, d=null]), []),
    ws_send(WS, text(Data)).

send_identify(WS):-
    format("sending identify\n"),
    bot_token(Token),


    atom_json_term(Data, json([
        op=2,
        d=json([
            token=Token,
            properties=json([
                os='Linux',
                browser='powered-by-prolog',
                device='powered-by-prolog'
            ])
        ])
    ]), []),

    print(Data),
    ws_send(WS, text(Data)).

websocket_loop(Client):-
    format("running loop\n"),
    (wait_for_input([Client.ws], [Da], 5) ->
        ws_receive(Da, Msg, [format(json)]),
        format("received data: ~w\n", [Msg.data]),
        handle_json(Msg.data)
        ; format("no data received\n")
    ),
    send_heartbeat(Client.ws),
    websocket_loop(Client).

handle_json(O):-
    O.op = 11,
    format("heartbeat received\n").

handle_json(O):-
    O.op = 0,
    format("Received event: ~w\n", O.t).

handle_json(O):-
    format("discarding data for op ~p", O.op).

:-
    debug,
    gateway_url(URL),
    http_open_websocket(URL, WS, []),
    set_stream(WS, timeout(60)),

    Client = client{ws: WS},

    ws_receive(Client.ws, Reply, [format(json)]),
    handle_json(Reply.data),

    send_identify(Client.ws),
    websocket_loop(Client),
    halt.
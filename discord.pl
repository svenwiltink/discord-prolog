:- use_module(library(http/websocket)).
:- use_module(library(http/json)).

gateway_url("wss://gateway.discord.gg/?v=6&encoding=json").
discord_endpoint("https://discord.com/api/v6").

discord_endpoint_messages(Url, ChannelId):-
    discord_endpoint(Endpoint),
    format(atom(Url), "~w/channels/~w/messages", [Endpoint, ChannelId]).

send_heartbeat(Client, UpdatedClient):-
    get_time(CurrentTime),
    TimeDiff is CurrentTime - Client.lastHeartBeat,
    format("Time since last heartbeat: ~p\n", [TimeDiff]),
    (TimeDiff > (Client.heartBeatInterval/1000)
    ->  format("time to send a heartbeat\n"),
        atom_json_term(Data, json([op=1, d=Client.lastSequence]), []),
        ws_send(Client.ws, text(Data)),
        UpdatedClient = Client.put([lastHeartBeat=CurrentTime])
    ;   UpdatedClient = Client
    ).

send_identify(Client):-
    atom_json_term(Data, json([
        op=2,
        d=json([
            token=Client.token,
            properties=json([
                os='Linux',
                browser='powered-by-prolog',
                device='powered-by-prolog'
            ])
        ])
    ]), []),

    format("sending identify: ~w\n", [Data]),
    ws_send(Client.ws, text(Data)).

websocket_loop(Client):-
    format("running loop\n"),
    (wait_for_input([Client.ws], [Da], 1)
    ->  ws_receive(Da, Msg, [format(json)]),
        format("received data: ~w\n", [Msg.data]),
        handle_json(Client, Msg.data, NewClient)
    ;   format("no data received\n"),
        NewClient = Client
    ),
    send_heartbeat(NewClient, NewClient2),
    websocket_loop(NewClient2).

handle_json(Client, O, UpdatedClient):-
    O.op = 10,
    format("hello received\n"),
    get_time(Time),
    UpdatedClient = Client.put([lastHeartBeat=Time,heartBeatInterval=O.d.heartbeat_interval]).

handle_json(Client, O, Client):-
    O.op = 11,
    format("heartbeat received\n").

handle_json(Client, O, NewClient):-
    O.op = 0,
    NewClient = Client.put([lastSequence=O.s]),
    format("Received event: ~w\n", O.t),
    call_handlers(Client, Client.handlers, O).

handle_json(Client, O, Client):-
    format("discarding data for op ~p\n~p\n", [O.op, O]).

call_handlers(_, [], _).

call_handlers(Client, [H|T], Event):-
    (call(H, Client, Event.t, Event.d)
    -> call_handlers(Client, T, Event)
    ;  call_handlers(Client, T, Event)
    ).

discord_client_create(Token, Client):-
    Client = client{token: Token, handlers: [], lastSequence: null}.

discord_client_add_handler(Client, Handler, NewClient):-
    NewHandlers = [Handler|Client.handlers],
    NewClient = Client.put([handlers=NewHandlers]).

discord_message_create(Client, ChannelId, Message, ResponseMsg):-
    atom_json_term(Payload, json([
        content=Message
    ]), []),

    discord_endpoint_messages(URL, ChannelId),
    http_post(
        URL,
        atom("application/json", Payload),
        Response, [
        request_header("Authorization"=Client.token)
    ]),

    atom_json_dict(Response, ResponseMsg, []).

discord_client_run(Client):-
    gateway_url(URL),
    http_open_websocket(URL, WS, []),
    set_stream(WS, timeout(60)),

    ClientWithSocket = Client.put([ws: WS]),

    ws_receive(ClientWithSocket.ws, Reply, [format(json)]),
    handle_json(ClientWithSocket, Reply.data, NewClient),

    send_identify(NewClient),
    websocket_loop(NewClient).
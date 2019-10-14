module WebSocket exposing (WebSocketCmd(..), WebSocketMsg(..), decodeMsg, encodeCmd, receive, send)

{-| WebSocket.

This Elm module lets you encode and decode messages to pass to javascript.

You'll need some JS code to do the actual websocket sending and receiving. That code
is right here:

      <script>
        var mySockets = {};

        function sendSocketCommand(wat) {
          // console.log( "ssc: " +  JSON.stringify(wat, null, 4));
          if (wat.cmd == "connect")
          {
            // console.log("connecting!");
            socket = new WebSocket(wat.address, wat.protocol);
            socket.onmessage = function (event) {
              // console.log( "onmessage: " +  JSON.stringify(event.data, null, 4));
              app.ports.receiveSocketMsg.send({ name : wat.name
                                              , msg : "data"
                                              , data : event.data} );
            }
            mySockets[wat.name] = socket;
          }
          else if (wat.cmd == "send")
          {
            // console.log("sending to socket: " + wat.name );
            mySockets[wat.name].send(wat.content);
          }
          else if (wat.cmd == "close")
          {
            // console.log("closing socket: " + wat.name);
            mySockets[wat.name].close();
            delete mySockets[wat.name];
          }
        }
      </script>

Put the above in your index.html or whatever.

Then in your Main.elm, you'll want to make some ports like this:

port receiveSocketMsg : (JD.Value -> msg) -> Sub msg
port sendSocketCommand : JE.Value -> Cmd msg

See below for usage specifics. Lastly, you'll need to set up the port function in
javascript, as in this example (the subscribe line).

      <script>
        var app = Elm.Main.init( { node: document.getElementById("elm") });
        if (document.getElementById("elm"))
        {
          document.getElementById("elm").innerText = 'This is a headless program, meaning there is nothing to show here.\\n\\nI started the program anyway though, and you can access it as `app` in the developer console.';
        }
        // Add this line!
        app.ports.sendSocketCommand.subscribe(sendSocketCommand);
      </script>

-}

import Json.Decode as JD
import Json.Encode as JE


{-| use send to make a websocket convenience function,
like so:

      port sendSocketCommand : JE.Value -> Cmd msg

      wssend =
          WebSocket.send sendSocketCommand

then you can call (makes a Cmd):

      wssend <|
          WebSocket.Send
              { name = "touchpage"
              , content = dta
              }

-}
send : (JE.Value -> Cmd msg) -> WebSocketCmd -> Cmd msg
send portfn wsc =
    portfn (encodeCmd wsc)


{-| make a subscription function with receive and a port, like so:

      port receiveSocketMsg : (JD.Value -> msg) -> Sub msg

      wsreceive =
          receiveSocketMsg <| WebSocket.receive WsMsg

Where WsMessage is defined in your app like this:

      type Msg
          = WsMsg (Result JD.Error WebSocket.WebSocketMsg)
          | <other message types>

then in your application subscriptions:

      subscriptions =
          \_ -> wsreceive

-}
receive : (Result JD.Error WebSocketMsg -> msg) -> (JD.Value -> msg)
receive wsmMsg =
    \v ->
        JD.decodeValue decodeMsg v
            |> wsmMsg


{-| messages going out from Elm to be processed in javascript.
name: You should give each websocket connection a unique name.
address: is the websocket address, for instance "<ws://127.0.0.1:9000">.
protocol: is an extra string to help the server know what kind of data to expect, like
if your server handled json or binary data. Probably you can pass it "".
-}
type WebSocketCmd
    = Connect { name : String, address : String, protocol : String }
    | Send { name : String, content : String }
    | Close { name : String }


{-| responses from javascript after websocket operations.
The name is the one you have the socket in Connect.
-}
type WebSocketMsg
    = Error { name : String, error : String }
    | Data { name : String, data : String }


{-| encode websocket commands into json.
-}
encodeCmd : WebSocketCmd -> JE.Value
encodeCmd wsc =
    case wsc of
        Connect msg ->
            JE.object
                [ ( "cmd", JE.string "connect" )
                , ( "name", JE.string msg.name )
                , ( "address", JE.string msg.address )
                , ( "protocol", JE.string msg.protocol )
                ]

        Send msg ->
            JE.object
                [ ( "cmd", JE.string "send" )
                , ( "name", JE.string msg.name )
                , ( "content", JE.string msg.content )
                ]

        Close msg ->
            JE.object
                [ ( "cmd", JE.string "close" )
                , ( "name", JE.string msg.name )
                ]


{-| decode incoming messages from the websocket javascript.
-}
decodeMsg : JD.Decoder WebSocketMsg
decodeMsg =
    JD.field "msg" JD.string
        |> JD.andThen
            (\msg ->
                case msg of
                    "error" ->
                        JD.map2 (\a b -> Error { name = a, error = b })
                            (JD.field "name" JD.string)
                            (JD.field "error" JD.string)

                    "data" ->
                        JD.map2 (\a b -> Data { name = a, data = b })
                            (JD.field "name" JD.string)
                            (JD.field "data" JD.string)

                    unk ->
                        JD.fail <| "unknown websocketmsg type: " ++ unk
            )

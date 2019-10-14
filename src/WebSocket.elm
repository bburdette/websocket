module WebSocket exposing (WebSocketCmd(..), WebSocketMsg(..), decodeMsg, encodeCmd, receive, send)

{-| WebSocket.

This WebSocket Elm module lets you encode and decode messages to pass to javascript,
where the actual websocket sending and receiving will take place. See the README for more.

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

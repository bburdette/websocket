module WebSocket exposing
    ( WebSocketCmd(..)
    , WebSocketMsg(..)
    , decodeMsg
    , encodeCmd
    , receive
    , send
    , SocketClosure(..), showSocketClosure, socketClosure, socketClosureCode
    )

{-| This WebSocket Elm module lets you encode and decode messages to pass to javascript,
where the actual websocket sending and receiving will take place. See the README for more.

@docs WebSocketCmd
@docs WebSocketMsg
@docs decodeMsg
@docs encodeCmd
@docs receive
@docs send

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


{-| WebSocketCmds go from from elm out to javascript to be processed.

  - name: You should give each websocket connection a unique name.
  - address: is the websocket address, for instance "<ws://127.0.0.1:9000">.
  - protocol: is an extra string to help the server know what kind of data to expect, like
    if your server handled either json or binary data. Probably you can just pass it "".
  - content: the data you're sending through the socket.

-}
type WebSocketCmd
    = Connect { name : String, address : String, protocol : String }
    | Send { name : String, content : String }
    | Close { name : String }


{-| WebSocketMsgs are responses from javascript to elm after websocket operations.
The name should be the same string you used in Connect.

close event codes are documented here:
<https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent/code>

-}
type WebSocketMsg
    = OnOpen { name : String }
    | OnClose { name : String, code : SocketClosure }
    | OnError { name : String }
    | OnData { name : String, data : String }


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
                        JD.map (\a -> OnError { name = a })
                            (JD.field "name" JD.string)

                    "data" ->
                        JD.map2 (\a b -> OnData { name = a, data = b })
                            (JD.field "name" JD.string)
                            (JD.field "data" JD.string)

                    "close" ->
                        JD.map2 (\a b -> OnClose { name = a, code = b })
                            (JD.field "name" JD.string)
                            (JD.field "code" (JD.map socketClosure JD.int))

                    "open" ->
                        JD.map (\a -> OnOpen { name = a })
                            (JD.field "name" JD.string)

                    unk ->
                        JD.fail <| "unknown websocketmsg type: " ++ unk
            )


type SocketClosure
    = NormalClosure
    | GoingAway
    | Protocolerror
    | UnsupportedData
    | Reserved
    | NoStatusReceived
    | AbnormalClosure
    | InvalidFramePayloadData
    | PolicyViolation
    | MessageTooBig
    | MandatoryExtension
    | InternalError
    | ServiceRestart
    | TryAgainLater
    | BadGateway
    | TLSHandshake
    | Other Int


socketClosure : Int -> SocketClosure
socketClosure code =
    case code of
        1000 ->
            NormalClosure

        1001 ->
            GoingAway

        1002 ->
            Protocolerror

        1003 ->
            UnsupportedData

        1004 ->
            Reserved

        1005 ->
            NoStatusReceived

        1006 ->
            AbnormalClosure

        1007 ->
            InvalidFramePayloadData

        1008 ->
            PolicyViolation

        1009 ->
            MessageTooBig

        1010 ->
            MandatoryExtension

        1011 ->
            InternalError

        1012 ->
            ServiceRestart

        1013 ->
            TryAgainLater

        1014 ->
            BadGateway

        1015 ->
            TLSHandshake

        _ ->
            Other code


socketClosureCode : SocketClosure -> Int
socketClosureCode sc =
    case sc of
        NormalClosure ->
            1000

        GoingAway ->
            1001

        Protocolerror ->
            1002

        UnsupportedData ->
            1003

        Reserved ->
            1004

        NoStatusReceived ->
            1005

        AbnormalClosure ->
            1006

        InvalidFramePayloadData ->
            1007

        PolicyViolation ->
            1008

        MessageTooBig ->
            1009

        MandatoryExtension ->
            1010

        InternalError ->
            1011

        ServiceRestart ->
            1012

        TryAgainLater ->
            1013

        BadGateway ->
            1014

        TLSHandshake ->
            1015

        Other code ->
            code


showSocketClosure : SocketClosure -> String
showSocketClosure sc =
    case sc of
        NormalClosure ->
            "Normal Closure"

        GoingAway ->
            "Going Away"

        Protocolerror ->
            "Protocolerror"

        UnsupportedData ->
            "Unsupported Data"

        Reserved ->
            "Reserved"

        NoStatusReceived ->
            "No Status Received"

        AbnormalClosure ->
            "Abnormal Closure"

        InvalidFramePayloadData ->
            "Invalid Frame Payload Data"

        PolicyViolation ->
            "Policy Violation"

        MessageTooBig ->
            "Message Too Big"

        MandatoryExtension ->
            "Mandatory Extension"

        InternalError ->
            "Internal Error"

        ServiceRestart ->
            "Service Restart"

        TryAgainLater ->
            "Try Again Later"

        BadGateway ->
            "Bad Gateway"

        TLSHandshake ->
            "TLS Handshake"

        Other i ->
            "Unknown code: " ++ String.fromInt i

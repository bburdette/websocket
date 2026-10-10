# WebSocket

Dead simple websocket implementation for elm.


The WebSocket Elm module lets you encode and decode messages to pass to javascript.

You'll need some JS code to do the actual websocket sending and receiving. That code
is right here:

    <script>
        // websockets
        var mySockets = {};
        var sockQueue = {};

        function sendSocketCommand(sc) {
            // console.log( "ssc: " +  JSON.stringify(sc, null, 4));
            if (sc.cmd == "connect")
            {
                // console.log("connecting!");
                let socket = new WebSocket(sc.address);
                socket.onmessage = function (event) {
                    // console.log( "onmessage: " +  JSON.stringify(event.data, null, 4));
                    app.ports.receiveSocketMsg.send(
                        { name : sc.name
                        , msg : "data"
                        , data : event.data}
                    );
                };
                socket.onopen = function (event) {
                    // console.log( "onopen, websocket: \"" + sc.name + "\"");
                    let sq = sockQueue[sc.name];
                    if (sq) {
                        for (let msg of sq) {
                            mySockets[sc.name].send(msg);
                        }
                        sockQueue[sc.name] = [];
                    }
                };
                socket.addEventListener("close", function (event) {
                    // console.log( "socket close: ", event);
                    app.ports.receiveSocketMsg.send(
                        { name : sc.name
                        , msg : "close"
                        , code : event.code }
                    );
                });
                socket.addEventListener("error", function (event) {
                    // console.log( "socket error: " +  JSON.stringify(event.data, null, 4));
                    app.ports.receiveSocketMsg.send(
                        { name : sc.name
                        , msg : "error"
                        , error : event.data}
                    );
                });
                mySockets[sc.name] = socket;
            }
            else if (sc.cmd == "send")
            {
                // console.log("sending to socket: " + sc.name, mySockets[sc.name].readyState);
                if (mySockets[sc.name].readyState) {
                    mySockets[sc.name].send(sc.content);
                    } else
                    {
                        // console.log("queuing message", sc.name, sc.content);
                        let sq = sockQueue[sc.name];
                        if (sq) {
                            sq.push(sc.content);
                            } else {
                                sq = [sc.content];
                            }
                            sockQueue[sc.name] = sq;
                        }
                    }
                    else if (sc.cmd == "close")
                    {
                        // don't trigger close event when initiated from elm.
                        mySockets[sc.name].removeEventListener("close");
                        mySockets[sc.name].close();
                        delete mySockets[sc.name];
                    }
              }
    </script>

Put the above in your index.html or whatever.

Then in your Main.elm (or wherever you define your ports), you'll want to make 
some ports like this:

    port receiveSocketMsg : (JD.Value -> msg) -> Sub msg
    port sendSocketCommand : JE.Value -> Cmd msg

See the WebSocket module for usage specifics. 

Lastly, you'll need to set up the port function in javascript, as in this example (the subscribe line).

      <script>
        var app = Elm.Main.init( { node: document.getElementById("elm") });
        if (document.getElementById("elm"))
        {
          document.getElementById("elm").innerText = 'This is a headless program, meaning there is nothing to show here.\\n\\nI started the program anyway though, and you can access it as `app` in the developer console.';
        }
        // Add this line!
        app.ports.sendSocketCommand.subscribe(sendSocketCommand);
      </script>

There's no example code here yet, but [touchpage](https://github.com/bburdette/touchpage) uses websocket. Requires rust.

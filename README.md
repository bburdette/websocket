# WebSocket

Dead simple websocket implementation for elm.


The WebSocket Elm module lets you encode and decode messages to pass to javascript.

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

Then in your Main.elm (or wherever you define your ports), you'll want to make 
some ports like this:

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



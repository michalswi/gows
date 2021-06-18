package main

import (
	"flag"
	"html/template"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/websocket"
)

// base on:
// https://github.com/gorilla/websocket/tree/master/examples/echo

var addr = flag.String("addr", "localhost", "http service address")
var port = flag.String("port", "8080", "http service port")

var upgrader = websocket.Upgrader{} // use default options

var logger = log.New(os.Stdout, "server ", log.LstdFlags|log.Lshortfile|log.Ltime|log.LUTC)

func echo(w http.ResponseWriter, r *http.Request) {
	c, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		logger.Print("upgrade:", err)
		return
	}
	defer c.Close()
	for {
		mt, message, err := c.ReadMessage()
		if err != nil {
			logger.Println("read:", err)
			break
		}
		logger.Printf("recv: %s", message)
		err = c.WriteMessage(mt, message)
		if err != nil {
			logger.Println("write:", err)
			break
		}
	}
}

func home(w http.ResponseWriter, r *http.Request) {
	logger.Printf("home endpoint: %s", r.Method)
	homeTemplate.Execute(w, "ws://"+r.Host+"/echo")
}

func hc(w http.ResponseWriter, r *http.Request) {
	logger.Printf("hc endpoint: %s", r.Method)
	w.Write([]byte("ok"))
}

func main() {
	flag.Parse()
	http.HandleFunc("/echo", echo)
	http.HandleFunc("/", home)
	http.HandleFunc("/hc", hc)
	logger.Println("Server is ready to handle requests at port", port)
	logger.Fatal(http.ListenAndServe(*addr+":"+*port, nil))
}

var homeTemplate = template.Must(template.New("").Parse(`
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>GoWebSocket</title>
<script>  
window.addEventListener("load", function(evt) {

    var output = document.getElementById("output");
    var input = document.getElementById("input");
    var ws;

    var print = function(message) {
        var d = document.createElement("div");
        d.textContent = message;
        output.appendChild(d);
        output.scroll(0, output.scrollHeight);
    };

    document.getElementById("open").onclick = function(evt) {
        if (ws) {
            return false;
        }
        ws = new WebSocket("{{.}}");
        ws.onopen = function(evt) {
            print("OPEN");
        }
        ws.onclose = function(evt) {
            print("CLOSE");
            ws = null;
        }
        ws.onmessage = function(evt) {
            print("RESPONSE: " + evt.data);
        }
        ws.onerror = function(evt) {
            print("ERROR: " + evt.data);
        }
        return false;
    };

    document.getElementById("send").onclick = function(evt) {
        if (!ws) {
            return false;
        }
        print("SEND: " + input.value);
        ws.send(input.value);
        return false;
    };

    document.getElementById("close").onclick = function(evt) {
        if (!ws) {
            return false;
        }
        ws.close();
        return false;
    };

});
</script>
</head>
<body>
<table>
<tr><td valign="top" width="50%">
<p>Click "Open" to create a connection to the server, 
"Send" to send a message to the server and "Close" to close the connection. 
You can change the message and send multiple times.
<p>
<form>
<button id="open">Open</button>
<button id="close">Close</button>
<p><input id="input" type="text" value="Hello world!">
<button id="send">Send</button>
</form>
</td><td valign="top" width="50%">
<div id="output" style="max-height: 70vh;overflow-y: scroll;"></div>
</td></tr></table>
</body>
</html>
`))

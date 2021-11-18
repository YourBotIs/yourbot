var WebSocket = require('faye-websocket')

const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MzcyNDk0NTYsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6NDAwMCIsIm5vbmNlIjoiQkFFMjhCMkI4NzA0OURCMzdBQTdFMzI4QkZERDM5MjhBOUMzQTZFMDkyQkYxQUFFQUM2Q0IzRkEyNUNDRTg4NjcxNTczRDIyMUQzNzc4NEUyNjA1RUM4NEY4MTQ3QzcwMUNGMTNDNEYyOUIyMjVGOTM1MDU3NUQyRTM2MkZGQUYiLCJzY29wZSI6ImFkbWluIiwidXNlcl9pZCI6MX0.zduRBHYb0ceCg5uE2AO0anKvoYl9iTVaN0bpxZXU7js"
const bot_id = 1;
const url = 'ws://localhost:4000/api/bots/console?authorization=' + token + "&bot_id=" + bot_id

class RPC {
  constructor(id, kind, action, args) {
    this.id = id;
    this.kind = kind;
    this.action = action;
    this.args = args;
  }

  encode() {
    let rpc = { id: this.id, kind: this.kind, action: this.action, args: this.args };
    return JSON.stringify(rpc);
  }
}

/**
 * Example wrapper around a Websocket connection to yourbotis.live
 */
class BotSocket {
  constructor(url) {
    this.url = url;
    // Will be the WebSocket client when connect() is called
    this.ws = null;
    // A object that will be used to store promises and unresolved RPCs
    this.rpcs = {};
  }

  /**
   * Attempt to connect to the socket. Does not send any data
   * @returns Promise
   */
  connect() {
    // This is an external library, but it works pretty much
    // just like the browser JS library
    this.ws = new WebSocket.Client(this.url);

    // set the callback for resolving RPCs.
    // Suggest reading it's source
    let that = this;
    this.ws.on('message', function (event) {
      that.handleRPC.call(that, event);
    });

    let ws = this.ws;

    let promise = new Promise(function (onConnect, onError) {
      // Called when this socket is opened on the server.
      ws.on('open', function (event) {
        // if a new socket opens, we have to reject all pending RPCs as the server will have no record of them.
        for (const id in that.rpcs) {
          that.rpcs[id].reject(event);
          delete that.rpcs[id];
        }

        // resolve the `connect()` promise
        onConnect()
      });

      // called when the server closes the connection. 
      // This will happen in a number of cases, most notably if the token or bot_id are invalid, 
      // but it will also be called when the server goes down for a deploy, or even for an unexpected crash etc.
      ws.on('close', function (event) {
        // When the socket closes, we have to reject all pending RPCs.
        for (const id in that.rpcs) {
          that.rpcs[id].reject(event);
          delete that.rpcs[id];
        }

        // reject the `connect()` promise
        onError();
      });

      // Called when a network error happens.
      // usually (but not always) assosiacted with a `close` event
      // shortly after.
      ws.on('error', function (event) {
        // reject all rpcs. This would happen anyway
        // when the server `close`s the connection shortly.
        for (const id in that.rpcs) {
          that.rpcs[id].reject(event);
          delete that.rpcs[id];
        }
      });
    });

    return promise;
  }

  // called when a message is delivered to the socket
  handleRPC(event) {
    // get JSON out of the message
    let data = JSON.parse(event.data);
    // Parse it as a RPC
    let reply = new RPC(data["id"], data["kind"], data["action"], data["args"]);

    // Look up the rpc's ID in the list
    let item = this.rpcs[data["id"]];
    if (item) {
      // reject the promise if kind is error
      if (reply.kind === "error") {
        item.reject(reply.args);
        delete this.rpcs[data["id"]];
      }
      // otherwise, resolve
      else {
        item.resolve(reply.args);
        delete this.rpcs[data["id"]];
      }
    } else {
      console.log("unknown response", data)
    }
  }

  /**
   * Send an RPC on the socket
   * @param {*} kind 
   * @param {*} action 
   * @param {*} args 
   * @returns Promise
   */
  rpc(kind, action, args) {
    // id is used to resolve the promise in the future. Grab the current datetime as it should be pretty unique
    let id = new Date().valueOf();

    // Add a new RPC to the socket state. It will be resolved 
    // later when handleRPC is called.
    // This data will get `delete`d after the promise is reject/resolved.
    let rpc = new RPC(id, kind, action, args);
    this.rpcs[id] = {
      rpc: rpc,
      resolve: null,
      reject: null
    };
    let that = this;

    // This is the promise that will be resolved in the future.
    // consideration: what if the server never responds? Probably needs a timeout
    let promise = new Promise(function (resolve, reject) {
      that.rpcs[id].resolve = resolve;
      that.rpcs[id].reject = reject;
    });

    // fire off the message
    this.ws.send(rpc.encode());
    return promise;
  }
}

/* example client code */

// Create a socket
const socket = new BotSocket(url);

// Connect returns a promise that will resolve to a connected state.
// A future addition might be to enable queueing RPCs before that
// resolution happens, but i was too lazy to implement that.
// What this means is that RPCs shouldn't be sent before this 
// promise resolves
socket.connect()
  // As stated above, this is called when the socket is successfully connected.
  .then(function (event) {
    console.log("connected");

    // Example sending of a not implemented RPC. 
    socket.rpc("test", "action", {})
      // This Promise will never resolve.
      .then(function (event) {
        console.log("that worked!", event);
      })
      // captures the error of the RPC. In this case, it will always say 'unknown command'
      .catch(function (error) {
        console.log("error resolving rpc", error)
      });
  })
  // Called if the server rejects our token or just isn't online.
  .catch(function (event) {
    console.log("connect error", event.message);
  });
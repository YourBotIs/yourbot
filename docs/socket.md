# YourBot Socket API

## Connecting

The websocket URL exists at `/api/bots/console`. there are two required parameters that must be
passed in: 

`authorization` - user scoped, encoded JWT
`bot_id` - ID of the bot the socket should be attached too

for development this socket connection might look something like:

```javascript
const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MzcyNDk0NTYsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6NDAwMCIsIm5vbmNlIjoiQkFFMjhCMkI4NzA0OURCMzdBQTdFMzI4QkZERDM5MjhBOUMzQTZFMDkyQkYxQUFFQUM2Q0IzRkEyNUNDRTg4NjcxNTczRDIyMUQzNzc4NEUyNjA1RUM4NEY4MTQ3QzcwMUNGMTNDNEYyOUIyMjVGOTM1MDU3NUQyRTM2MkZGQUYiLCJzY29wZSI6ImFkbWluIiwidXNlcl9pZCI6MX0.zduRBHYb0ceCg5uE2AO0anKvoYl9iTVaN0bpxZXU7js"
const bot_id = 1;
const url = 'ws://localhost:4000/api/bots/console?authorization=' + token + "&bot_id=" + bot_id;
```

For production, it should be the same, however one will need to use something more like:

```javascript
const url = 'wss://api.yourbotis.live/api/bots/console?authorization=' + token + "&bot_id=" + bot_id;
```

## Remote Procedure Calls

The socket API uses a specific format, encoded as JSON. The general shape of the messages will look like:

```json
{
  "id": "1637247203",
  "kind": "command", 
  "action": "subcommand", 
  "args": {
    "any": ["data"]
  }
}
```

All root level fields are required. Below is description of the fields:

* `id`     - string - Identifier of the message. This can be used for resolution of calls. The field is required, but it may be null.
* `kind`   - string - The kind of command that is being sent. 
* `action` - string - The action that should be performed, or is in reference too.
* `args`   - object - Key/Value object of arguments that will be populated. This field is required, but not always populated.

## RPC descriptions

Below is a list of all the currently implemented RPCS.

### Kind: Error

Any command request from a client may return an error. 

| kind      | Action            | Args                              | Description                 |
|:---------:|-------------------|-----------------------------------|-----------------------------|
| `error`   | `start_child`     | `message`                         | error response to a `sandbox.start` RPC |
| `error`   | `terminate_child` | `message`                         | error response to a `sandbox.stop` RPC |
| `error`   | `handle_rpc`      | `message`                         | error response to an unknown RPC |

### Kind: Sandbox

| kind      | Action     | Args                              | Description                 |
|:---------:|------------|-----------------------------------|-----------------------------|
| `sandbox` | `start`    | none                              | Start a stopped bot sandbox |
| `sandbox` | `stop`     | none                              | Stop a started bot sandbox  |
| `sandbox` | `status`   | `deploy_status`,`uptime_status`   | Request or response of the bot's current status |
| `sandbox` | `tty_data` | `message`                         | Raw stdout data from Python |

Note that `status` and `tty_data` will be sent **from** the server **to** the client asyncronously.
`stats` can be sent from the client to the server to request the current status from the server. Note that
upon connection, the server will automatically send the current bot's status so the client doesn't need 
to request it. 

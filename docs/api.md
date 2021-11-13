# Yourbotis.live API docs

## /api/users

* GET /api/users - list users
* POST /api/users - create a user
* GET /api/users/:discord_id - show a user
* PATCH /api/users/:discord_id - update a user
* DELETE /api/users/:discord_id - delete a user

### User Required Params

* `discord_id` - user's discord id
* `username` - user's discord username
* `discriminator` user's discord discriminator

### User Optional Params

* `email` - user's email
* `avatar` - users avatar slug

## /api/bots

* GET /api/bots - list bots
* POST /api/bots - create a bot
* GET /api/bots/:id - show a bot
* PATCH /api/bots/:id - update a bot
* DELETE /api/bots/:id - delete a bot

### Bot Required Params

* `user` - user's discord id
* `bot` - params for creating and updating a bot
  * `name` - string, bot name
  * `application_id` - integer, discord application id
  * `public_key` - string, discord bot public key
  * `token` - string, discord bot token

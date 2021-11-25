# Copyright (C) PressY4Pie#0690 - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential
# Written by PressY4Pie#0690, November 2021
#
# You're under no obligation to choose a license. A sample one has been provided to you aboce.
# It's your right not to include one with your code or project, but please be aware of the implications.
# Generally speaking, the absence of a license means that the default copyright laws apply.
# This means that you retain all rights to your source code and that nobody else may
# reproduce, distribute, or create derivative works from your work. This might not be what you intend.
# Even if this is what you intend, if you publish your source code in a public code on YourBot,
# you have accepted the Terms of Service which do allow other YourBot users some rights.
# Specifically, you allow others to view code within the YourBot site.

import discord
import asyncio
import sqlite3
import logging
import os
from datetime import datetime
import random

# Configure logging.
# You are free to remove this code, however logs will not sent to the web console
logger = logging.getLogger("MyClient")
logger.setLevel(logging.INFO)

# Setup a stream handler to write data to stdout.
# Stdout is piped directly to the web console
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
default_handler = logging.StreamHandler()
default_handler.setFormatter(formatter)

# install the handler
logger.addHandler(default_handler)

EIGHTBALL_ANSWERS = [
    "It is certain",
    "It is decidedly so",
    "Without a doubt",
    "Yes, definitely",
    "You may rely on it",
    "As I see it, yes",
    "Most likely",
    "Outlook good",
    "Yes",
    "Signs point to yes",
    "Reply hazy try again",
    "Ask again later",
    "Better not tell you now",
    "Cannot predict now",
    "Concentrate and ask again",
    "Don't count on it",
    "My reply is no",
    "My sources say no",
    "Outlook not so good",
    "Very doubtful ",
]


class MyClient(discord.Client):
    """
    This class is where most of your code should go.
    see the documentation for more information
    https://discordpy.readthedocs.io/en/stable/api.html#client
    """

    def __init__(self, con):
        """Called upon instanciation"""
        self.con = con
        super().__init__()

    def log_event(self, name, content):
        """
        Example usage of the sqlite database
        yourbot_event_log is the name of a special table that has
        been created for you. It contains 4 fields
        'name' - String - classification of the event
        'content' - String - value of the event
        'inserted_at' - utc_date_time
        'updated_at' - utc_date_time
        """

        with self.con:
            now = datetime.now()
            record = (name, content, now, now)
            qurry = "INSERT INTO yourbot_event_log ('name','content','inserted_at','updated_at') VALUES (?, ?, ?, ?)"
            cur = con.cursor()
            cur.execute(qurry, (record))

    def setup_tables(self):
        """Creates the drovemiata table and index for it"""
        with self.con:
            cur = con.cursor()
            # cur.execute("""
            # DROP TABLE drovemiata
            # """)
            cur.execute(
                """
            CREATE TABLE IF NOT EXISTS drovemiata (
                                                    id integer PRIMARY KEY,
                                                    user_id id NOT NULL,
                                                    count integer INTEGER DEFAULT 0
                                                ); 
            """
            )
            cur.execute(
                """
            CREATE UNIQUE INDEX IF NOT EXISTS drovemiata_user_unique_undex ON drovemiata ( user_id );
            """
            )
            cur.execute(
                """
            CREATE TABLE IF NOT EXISTS touchedmiata (
                                                    id integer PRIMARY KEY,
                                                    user_id id NOT NULL,
                                                    count integer INTEGER DEFAULT 0
                                                ); 
            """
            )
            cur.execute(
                """
            CREATE UNIQUE INDEX IF NOT EXISTS touchedmiata_user_unique_undex ON touchedmiata ( user_id );
            """
            )

    def get_drovemiata_count(self, author):
        """Returns the current drovemiata count for a user. If one doesn't exist, return None"""
        query = "SELECT count FROM drovemiata WHERE user_id=:user_id"
        with self.con:
            cur = con.cursor()
            cur.execute(query, {"user_id": author.id})
            return cur.fetchone()

    def drovemiata(self, author):
        """Increment the count for a user. If one isn't found, it will be set to 1. Returns the updated count."""
        count = self.get_drovemiata_count(author)
        with self.con:
            cur = con.cursor()
            if count == None:
                logger.info("no count for {0}!".format(self.user))
                query = "INSERT INTO drovemiata ('user_id', 'count') VALUES (?, ?)"
                cur.execute(query, (author.id, 1))
                return 1
            else:
                logger.info("count found for {0}".format(self.user))
                query = """
                UPDATE drovemiata
                SET count = ?
                WHERE user_id = ?;
                """
                cur.execute(query, (count[0] + 1, author.id))
                return count[0] + 1

    def get_touchedmiata_count(self, author):
        """Returns the current touchedmiata count for a user. If one doesn't exist, return None"""
        query = "SELECT count FROM touchedmiata WHERE user_id=:user_id"
        with self.con:
            cur = con.cursor()
            cur.execute(query, {"user_id": author.id})
            return cur.fetchone()

    def touchedmiata(self, author):
        """Increment the count for a user. If one isn't found, it will be set to 1. Returns the updated count."""
        count = self.get_touchedmiata_count(author)
        with self.con:
            cur = con.cursor()
            if count == None:
                logger.info("no count for {0}!".format(self.user))
                query = "INSERT INTO touchedmiata ('user_id', 'count') VALUES (?, ?)"
                cur.execute(query, (author.id, 1))
                return 1
            else:
                logger.info("count found for {0}".format(self.user))
                query = """
                UPDATE touchedmiata
                SET count = ?
                WHERE user_id = ?;
                """
                cur.execute(query, (count[0] + 1, author.id))
                return count[0] + 1

    async def on_ready(self):
        """This callback is called when your client successfully connects to Discord"""
        logger.info("Logged on as {0}!".format(self.user))
        self.log_event("on_ready", self.user.name + "#" + self.user.discriminator)

    # This callback is called whenever anyone posts a message
    async def on_message(self, message):
        # logger.info('Message from {0.author}: {0.content}'.format(message))
        # Ignore messages from self
        if message.author.id != self.user.id:
            lowered_message = message.content.lower()
            if any(command in lowered_message for command in ["piss"]):
                self.log_event(
                    "piss", message.author.name + "#" + message.author.discriminator
                )
                await message.add_reaction("<:piss_tbh:875871698115764264>")

            if any(
                command in lowered_message
                for command in ["?drovemiata", "?droveamiata"]
            ):
                self.log_event(
                    "drovemiata",
                    message.author.name + "#" + message.author.discriminator,
                )
                count = self.drovemiata(message.author)
                await message.reply("Current miata driven count " + str(count))

            if any(
                command in lowered_message
                for command in ["?touchedmiata", "?touchedamiata"]
            ):
                self.log_event(
                    "touchedmiata",
                    message.author.name + "#" + message.author.discriminator,
                )
                count = self.touchedmiata(message.author)
                await message.reply("Current miata touched count " + str(count))

            if any(command in lowered_message for command in ["?8ball"]):
                await message.reply(random.choice(EIGHTBALL_ANSWERS))


# Instanciate a connection to an sqlite database
# this will be used in our client
con = sqlite3.connect(os.environ["DATABASE_URL"])

# Instanciate a client object and start it.
client = MyClient(con)
client.setup_tables()
asyncio.create_task(client.start(os.environ["DISCORD_TOKEN"]))

#!/usr/bin/python

import logging
import sys
import traceback
import sys
import argparse
import os
import shutil
import asyncio
import sqlite3

from term import Atom
from term import Pid
from pyrlang.gen.server import GenServer
from pyrlang.gen.decorators import call, cast, info
from pyrlang import Node

logger = logging.getLogger('YourBot.BotSandbox')
logger.setLevel(logging.DEBUG)

ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)

formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

class Sandbox(GenServer):
    def __init__(self, node, chroot, sandbox, database) -> None:
        self.node = node
        self.sandbox = sandbox
        self.database = database
        self.monitor = None

        if(chroot):
            os.chroot(chroot)
            os.chdir("/")

        try:
            os.mkdir(sandbox)
        except FileExistsError:
            logger.debug("not making directory - already exists")

        os.chdir(sandbox)

        # delete all files in this dir to start clean
        # will probably add to startup time, but be safer
        for files in os.listdir(sandbox):
            path = os.path.join(sandbox, files)
            try:
                shutil.rmtree(path)
            except OSError:
                os.remove(path)

        con = sqlite3.connect(database)
        cur = con.cursor()
        cur.execute("SELECT name,content FROM yourbot_files")
        records = cur.fetchall()
        for record in records:
            path = os.path.join(sandbox, record[0])
            f = open(path, "x")
            f.write(record[1])
            f.close()

        logger.info('extracted files')
        con.commit()
        con.close()

        super().__init__()

    async def bootstrap(self):
        logger.info("bootstrapping sandbox")
        entrypoint = os.path.join(self.sandbox, 'client.py')
        try:
            sys.path.append(self.sandbox)
            code = compile(open(entrypoint).read(), "client.py", "exec")
            result = exec(code, globals(), globals())
            await self.node.send(
                sender=self,
                receiver=self.monitor,
                message=(Atom("exec"), result)
            )
        except:
            traceback.print_exc()
            reason = str(sys.exc_info()[1]).encode('utf-8')
            summary = traceback.extract_stack()
            st = [(bytes(o.name, 'utf-8'), bytes(o.filename, 'utf-8'), o.lineno)
                  for o in summary]
            logger.info(st)
            await self.node.send(
                sender=self,
                receiver=self.monitor,
                message=(Atom("stacktrace"), reason, st)
            )

    @cast(1, lambda msg: type(msg) == tuple and msg[0] == Atom("handshake") and type(msg[1]) == Pid)
    async def handle_cast(self, msg):
        self.monitor = msg[1]
        await self.bootstrap()

def main():
    parser = argparse.ArgumentParser(description="Sandbox.py")
    parser.add_argument('--name', type=str,
                        help='Node Name', required=True)
    parser.add_argument('--cookie', type=str,
                        help='Node Cookie', required=True)
    parser.add_argument('--hidden', type=bool,
                        help='hidden node', required=False, default=False)
    parser.add_argument('--chroot', type=str,
                        help='path to chroot into', required=False)
    parser.add_argument('--sandbox', type=str,
                        help='path to extract the program into', required=True)
    parser.add_argument('--database', type=str,
                        help='path to the sqlite3 initialized and formatted database', required=True)
    parser.add_argument('--bootstrap', type=bool,
                        help='bootstrap after boot', required=False)
    args = parser.parse_args()

    node = Node(args.name, args.cookie, args.hidden)
    logger.info("node reachable at %s" % args.name)
    logger.info("registering process 'Elixir.YourBot.BotSandbox'")
    sandbox = Sandbox(node, args.chroot, args.sandbox, args.database)
    node.register_name(sandbox, Atom('Elixir.YourBot.BotSandbox'))
    if args.bootstrap:
        asyncio.run(sandbox.bootstrap())
    node.run()

if __name__ == "__main__":
    main()

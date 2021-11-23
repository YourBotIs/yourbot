#!/usr/bin/python

import logging
import sys
import traceback
import sys
import argparse
import os

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
    def __init__(self, node, chroot) -> None:
        if(chroot):
            os.chroot(chroot)
            os.chdir("/")
        self.node = node
        super().__init__()

    @cast(1, lambda msg: type(msg) == tuple and msg[0] == Atom("code") and type(msg[2]) == Pid)
    async def handle_cast(self, msg):
        try:
            code = compile(msg[1], "client.py", "exec")
            result = exec(code, globals(), globals())
            await self.node.send(
                    sender=self,
                    receiver=msg[2],
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
                    receiver=msg[2],
                    message=(Atom("stacktrace"), reason, st)
            )

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
    args = parser.parse_args()

    node = Node(args.name, args.cookie, args.hidden)
    logger.info("node reachable at %s" % args.name)
    logger.info("registering process 'Elixir.YourBot.BotSandbox'")
    sandbox = Sandbox(node, args.chroot)
    node.register_name(sandbox, Atom('Elixir.YourBot.BotSandbox'))
    node.run()

if __name__ == "__main__":
    main()

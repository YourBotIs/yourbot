#!/usr/bin/python

import logging
import sys
import traceback
import sys
import getopt
import argparse
import asyncio
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
    def __init__(self, node) -> None:
        super().__init__()

    @cast(1, lambda msg: type(msg) == tuple and msg[0] == Atom("code") and type(msg[2]) == Pid)
    def handle_cast(self, msg):
        try:
            os.chroot("/var/chroot")
            os.chdir("/")
            code = compile(msg[1], "client.py", "exec")
            exec(code, globals(), globals())
            # self.node.send_nowait()
        except:
            traceback.print_exc()
            reason = str(sys.exc_info()[1]).encode('utf-8')
            summary = traceback.extract_stack()
            st = [(bytes(o.name, 'utf-8'), bytes(o.filename, 'utf-8'), o.lineno)
                  for o in summary]
            logger.info(st)
            sys.exit("crash")

def main():
    parser = argparse.ArgumentParser(description="Sandbox.py")
    parser.add_argument('--name', type=str,
                    help='Node Name', required=True)
    parser.add_argument('--cookie', type=str,
                    help='Node Cookie', required=True)
    parser.add_argument('--hidden', type=bool,
                    help='hidden node', required=False, default=False)
    args = parser.parse_args()

    node = Node(args.name, args.cookie, args.hidden)
    logger.info("node reachable at %s" % args.name)
    logger.info("registering process 'Elixir.YourBot.BotSandbox'")
    sandbox = Sandbox(node)
    node.register_name(sandbox, Atom('Elixir.YourBot.BotSandbox'))
    node.run()


if __name__ == "__main__":
    main()

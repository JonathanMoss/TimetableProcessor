"""Module for consuming VSTP messagesfrom RMQ"""

# pylint: disable=import-error, wrong-import-position, no-name-in-module, unused-argument

import os
import sys
import inspect
import json
import pika
import pydantic

CURRENT_DIR = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
PARENT_DIR = os.path.dirname(CURRENT_DIR)
sys.path.insert(0, PARENT_DIR)

from broker.inbound_rmq_connection import InboundMqConnection


@pydantic.validate_call
def process_inbound(message: list) -> None:
    """Process the inbound message"""

    for msg in message:
        print(msg)

def callback(
        channel: pika.adapters.blocking_connection.BlockingChannel,
        method: pika.spec.Basic.Deliver,
        properties: pika.spec.BasicProperties,
        body: bytes):
    """RMQ callback function"""

    process_inbound(json.loads(body))

if __name__ == '__main__':

    SUB = InboundMqConnection(callback=callback, exchange='nrod-vstp')

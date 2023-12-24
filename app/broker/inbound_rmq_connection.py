"""Subscription only connection to RabbitMQ"""
# pylint: disable=import-error, wrong-import-position
import uuid
import inspect
import os
import logging
import sys
import pika

CURRENT_DIR = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
PARENT_DIR = os.path.dirname(CURRENT_DIR)
sys.path.insert(0, PARENT_DIR)

BROKER_CREDENTIALS = {
    'RMQ_HOST': os.getenv('RMQ_HOST', None),
    'RMQ_PORT': os.getenv('RMQ_PORT', '5672'),
    'RMQ_USER': os.getenv('RMQ_SUB_USER', None),
    'RMQ_PASS': os.getenv('RMQ_SUB_PASS', None),
    'EX_TYPE': os.getenv('EX_TYPE', 'fanout'),
    'HEARTBEAT': os.getenv('HEARTBEAT', '600'),
    'EXCHANGE': os.getenv('EXCHANGE', None)
    }

RETRY_DELAY = 5
SOCKET_TIMEOUT = 90
CONNECTION_ATTEMPTS = 10
BLOCKED_CONNECTION_TIMEOUT = 300
PREFETCH_COUNT = 5

# To reduce the verbosity of RMQ messages
logging.getLogger('pika').setLevel(logging.WARNING)

# Throw an error if there are missing credentials
if None in BROKER_CREDENTIALS.values():
    raise ValueError('Missing required credentials, please check environment variables')

def dummy_callback(
        channel: pika.adapters.blocking_connection.BlockingChannel,
        method: pika.spec.Basic.Deliver,
        properties: pika.spec.BasicProperties,
        body: bytes):
    """A dummy callback function that prints messages to STDOUT"""

    print(channel, method, properties, body)

class InboundMqConnection:
    """This class represents an object that subscribes to
    and receives messages from a RabbitMQ exchange"""

    def __init__(self, auto_start=True, callback=dummy_callback, exchange=None):
        """Initialisation"""

        if not exchange:
            self._exchange = BROKER_CREDENTIALS['EXCHANGE']
        else:
            self._exchange = exchange

        self._callback = callback

        self._conn = None
        self._channel = None
        self._queue = None
        self._queue_name = self.get_queue_name()

        self._define_connection()
        if auto_start:
            self.connect()

    def connect(self):
        """Connect and consume messages from the broker"""
        if self._channel:
            self._channel.start_consuming()

    def get_queue_name(self):
        """Returns a generated queue name"""
        return f'{uuid.uuid4().hex[0:7]}.{self._exchange}'

    @property
    def params(self):
        """Connection parameters"""

        return pika.ConnectionParameters(
            host=BROKER_CREDENTIALS['RMQ_HOST'],
            port=int(BROKER_CREDENTIALS['RMQ_PORT']),
            heartbeat=int(BROKER_CREDENTIALS['HEARTBEAT']),
            retry_delay=RETRY_DELAY,
            socket_timeout=SOCKET_TIMEOUT,
            connection_attempts=CONNECTION_ATTEMPTS,
            blocked_connection_timeout=BLOCKED_CONNECTION_TIMEOUT,
            credentials=pika.PlainCredentials(
                username=BROKER_CREDENTIALS['RMQ_USER'],
                password=BROKER_CREDENTIALS['RMQ_PASS']
            )
        )

    def _define_connection(self):
        """Define the connection, prior to connecting to the broker"""

        self._conn = pika.BlockingConnection(self.params)
        self._channel = self._conn.channel()
        self._channel.exchange_declare(
            exchange=self._exchange,
            exchange_type=BROKER_CREDENTIALS['EX_TYPE'],
            durable=True
        )

        self._queue = self._channel.queue_declare(
            queue=self._queue_name,
            exclusive=True,
            auto_delete=True
        )

        self._channel.queue_bind(
            exchange=self._exchange,
            queue=self._queue.method.queue
        )

        self._channel.basic_qos(
            prefetch_count=PREFETCH_COUNT
        )

        self._channel.basic_consume(
            self._queue.method.queue,
            self._callback,
            auto_ack=True
        )

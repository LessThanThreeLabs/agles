import pika

from settings import Settings


class RabbitSettings(Settings):
	def __init__(self):
		super(RabbitSettings, self).__init__(
			rabbit_host='localhost',
			rabbit_username='lt3',
			rabbit_password='42f6e8eacf66b9ee7c7b0a5b6a0e1498f7c0d42f')
		self.add_values(
			kombu_connection_info='pyamqp://%s:%s@%s//' % (self.rabbit_username, self.rabbit_password, self.rabbit_host),
			pika_connection_parameters=pika.ConnectionParameters(
				host=self.rabbit_host,
				credentials=pika.PlainCredentials(self.rabbit_username, self.rabbit_password)))

RabbitSettings.initialize()

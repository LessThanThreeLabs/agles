import pika

from settings import Settings


class RabbitSettings(Settings):
	def __init__(self):
		super(RabbitSettings, self).__init__(
			rabbit_host='localhost')
		self.add_values(
			kombu_connection_info='pyamqp://guest:guest@localhost//',
			pika_connection_parameters=pika.ConnectionParameters(
				host='localhost'))

RabbitSettings.initialize()

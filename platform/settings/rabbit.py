import pika

connection_info = 'amqp://guest:guest@localhost//'

connection_parameters = pika.ConnectionParameters(
		host='localhost')

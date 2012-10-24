import pika

connection_info = 'pyamqp://guest:guest@localhost//'

connection_parameters = pika.ConnectionParameters(
		host='localhost')

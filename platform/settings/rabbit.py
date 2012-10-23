import pika

connection_info = 'pyamqp://guest:guest@tadpole//'

connection_parameters = pika.ConnectionParameters(
		host='tadpole')

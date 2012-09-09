import pika

connection_parameters = pika.ConnectionParameters(
		host='localhost')
queue_name = "verification_node_queue"
box_name = "lucid32"
vm_count = 4

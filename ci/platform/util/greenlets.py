import eventlet; eventlet.monkey_patch(os=False)

def spawn_wrap(func):
	def wrapper(*args, **kwargs):
		eventlet.spawn(func, *args, **kwargs)
	return wrapper

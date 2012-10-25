import gevent

def spawn_wrap(func):
	def wrapper(*args, **kwargs):
		gevent.spawn(func, *args, **kwargs)
	return wrapper

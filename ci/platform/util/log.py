import logging
import logging.handlers
import os

LOG_HOME = './log'


def configure(log_home=LOG_HOME, filepath='/default.log'):
	# formatters
	simple_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
	# create log directory
	if not os.access(log_home, os.F_OK):
		os.makedirs(log_home)
	# handlers
	default_handler = logging.handlers.RotatingFileHandler(filename=log_home + filepath, maxBytes=8388608, backupCount=4)
	default_handler.setFormatter(simple_formatter)
	# loggers
	root_logger = logging.getLogger()
	root_logger.addHandler(default_handler)


class Logged(object):
	def __init__(self, level=logging.INFO):
		self.level = level

	def __call__(self, cls):
		class Wrapped(cls):
			cls.logger = logging.getLogger(cls.__name__)
			cls.logger.setLevel(self.level)
		return Wrapped

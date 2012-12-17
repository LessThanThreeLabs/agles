import logging
import logging.handlers
import os

LOG_HOME = './log'


def configure():
	# formatters
	simple_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
	# create log directory
	if not os.access(LOG_HOME, os.F_OK):
		os.makedirs(LOG_HOME)
	# handlers
	default_handler = logging.handlers.RotatingFileHandler(filename=LOG_HOME + '/default.log', maxBytes=8388608, backupCount=4)
	default_handler.setFormatter(simple_formatter)
	# loggers
	root_logger = logging.getLogger()
	root_logger.addHandler(default_handler)

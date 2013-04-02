import collections
import logging
import os

import eventlet

from settings.deployment import DeploymentSettings

LOG_HOME = './log'
CONFIGURED = False


def configure(log_home=LOG_HOME, filepath='/default.log'):
	if not CONFIGURED:
		_configure(log_home, filepath)


def _configure(log_home, filepath):
	global CONFIGURED
	CONFIGURED = True
	# formatters
	simple_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
	# create log directory
	if not os.access(log_home, os.F_OK):
		os.makedirs(log_home)
	# handlers
	default_handler = TimedBufferedMailHandler()  # logging.handlers.RotatingFileHandler(filename=log_home + filepath, maxBytes=8388608, backupCount=4)
	default_handler.setFormatter(simple_formatter)
	default_handler.setLevel(logging.WARN)
	# loggers
	root_logger = logging.getLogger()
	root_logger.addHandler(default_handler)
	root_logger.setLevel(logging.WARN)


class TimedBufferedMailHandler(logging.Handler):
	def __init__(self, max_records=100, buffer_time=10, send_level=logging.ERROR):
		super(TimedBufferedMailHandler, self).__init__()
		self.max_records = max_records
		self.buffered_records = collections.deque(maxlen=self.max_records)
		self.buffer_time = buffer_time
		self.send_level = send_level
		self.timer_greenlet = None

	def emit(self, record):
		self.buffered_records.append(record)
		if len(self.buffered_records) == self.buffered_records.maxlen and self.timer_greenlet is not None:
			self.flush()
		elif record.levelno >= self.send_level:
			self._begin_log_timer()
		else:
			eventlet.sleep()

	def _begin_log_timer(self):
		if self.timer_greenlet is not None:
			self.timer_greenlet.cancel()
		self.timer_greenlet = eventlet.spawn_after(self.buffer_time, self.flush)

	def flush(self):
		if self.timer_greenlet is not None:
			self.timer_greenlet.cancel()
		self.timer_greenlet = None
		if len(self.buffered_records) > 0 and any(map(lambda record: record.levelno >= self.send_level, self.buffered_records)):
			output_string = '\n'.join((self.format(record) for record in self.buffered_records))
			self.buffered_records = collections.deque(maxlen=self.max_records)
			self._send_log_mail(output_string)

	def _send_log_mail(self, output_string):
		try:
			deployment_info = "%s @ %s" % (DeploymentSettings.license, DeploymentSettings.version)
		except Exception as e:
			deployment_info = "FATAL"
			output_string = "Error while retrieving deployment info: %s\n\n%s" % (e, output_string)

		sendmail("logmailer@koalitycode.com", "logmailer@koalitycode.com",
			"%s Error: %s" % (self.name or 'root', deployment_info),
			output_string)


class Logged(object):
	def __init__(self, level=logging.DEBUG):
		self.level = level
		configure()

	def __call__(self, cls):
		handler = TimedBufferedMailHandler()
		handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
		handler.set_name(cls.__name__)
		# logfile = os.path.join(LOG_HOME, '%s.log' % cls.__name__)
		# handler = logging.handlers.RotatingFileHandler(filename=logfile, maxBytes=8388608, backupCount=4)

		cls.logger = logging.getLogger(cls.__name__)
		cls.logger.setLevel(self.level)
		cls.logger.addHandler(handler)
		return cls


from util.mail import sendmail


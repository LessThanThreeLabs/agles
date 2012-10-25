REDIS_KEY_TEMPLATE = "build.output:%s:%s" # build_id, console

class Console(object):
	General, Setup, Build, Test = range(4)

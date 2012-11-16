REDIS_KEY_TEMPLATE = "build.output:%s:%s:%s"  # build_id, type, subtype


class ConsoleType(object):
	Setup = "setup"
	Compile = "compile"
	Test = "test"

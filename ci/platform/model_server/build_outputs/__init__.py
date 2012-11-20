REDIS_SUBTYPE_KEY = "build.output:%s:%s:%s"  # build_id, type, subtype
REDIS_TYPE_KEY = "build.output:%s:%s" # build_id, type

def parse_subtype(subtype_key):
	return subtype_key.split(':')[3]

class ConsoleType(object):
	Setup = "setup"
	Compile = "compile"
	Test = "test"

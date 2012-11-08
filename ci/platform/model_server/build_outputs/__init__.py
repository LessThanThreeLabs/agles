REDIS_KEY_TEMPLATE = "build.output:%s:%s:%s"  # build_id, console, subcategory


class Console(object):
	General = "general"
	Setup = "setup"
	Build = "build"
	Test = "test"

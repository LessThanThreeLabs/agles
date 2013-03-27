from bunnyrpc.client import Client


def rpc_connect(route_noun, route_verb):
	route = "rpc:%s.%s" % (route_noun, route_verb)
	return Client("model:rpc", route)

import thread
import tornado.web
from BridgePython.bridge import Bridge


def createWebServer():
	class MainHandler(tornado.web.RequestHandler):
		def get(self):
			self.write("Hello, world")
	
	application = tornado.web.Application([
		(r"/", MainHandler),
	])
	application.listen(8888)


def createBridgeServer():
	bridge = Bridge(api_key='dfikjjgmhmdahhlg', host='127.0.0.1', port=8090)

	class HelloHandler(object):
		def hello(self, callback):
			callback('sup python nerd?')

	bridge.publish_service('helloWorld', HelloHandler())
	bridge.connect()


createWebServer()
createBridgeServer()
# thread.start_new_thread(createBridgeServer, ())
print 'python bridge server is running!!'
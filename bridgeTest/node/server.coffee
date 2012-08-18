bridge = new (require('bridge-js')) 
	apiKey: 'dfikjjgmhmdahhlg'
	host: '127.0.0.1'
	port: 8090
bridge.connect()

class HelloHandler
	hello: (callback) ->
		callback('sup node nerd?')

bridge.publishService 'helloWorld', new HelloHandler
console.log 'node bridge server is running!!'

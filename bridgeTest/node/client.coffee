bridge = new (require('bridge-js')) 
	apiKey: 'dfikjjgmhmdahhlg'
	host: '127.0.0.1'
	port: 8090
bridge.connect()

bridge.getService 'helloWorld', (handle) ->
	handle.hello (string) ->
		console.log string

console.log 'node bridge client running!!'

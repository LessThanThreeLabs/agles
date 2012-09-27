fs = require 'fs'
https = require 'https'
express = require 'express'
io = require 'socket.io'
redis = require 'redis'

RedisStore = require 'socket.io/lib/stores/redis'


_getHttpsOptions = () ->
	options = 
		key: fs.readFileSync 'keys/privatekey.pem'
		cert: fs.readFileSync 'keys/certificate.pem'
		ca: fs.readFileSync 'keys/certrequest.csr'


index = '<script src="socket.io/socket.io.js"></script>
	<script>
	  var socket = io.connect("https://127.0.0.1");
	  socket.on("news", function (data) {
	    console.log(data);
	    socket.emit("my other everabbitnt", { my: "data" });
	  });
	</script>'


expressServer = express()
expressServer.use '/', (request, response) =>
	response.send index
server = https.createServer _getHttpsOptions(), expressServer
server.listen 443

socketio = io.listen server
socketio.set 'store', new RedisStore
	redisClient: redis.createClient()
	redisPub: redis.createClient()
	redisSub: redis.createClient()

socketio.sockets.on 'connection', (socket) =>
	socket.emit 'news', hello: 'world'
	socket.on 'my other event', (data) ->
		console.log 'data: ' + data

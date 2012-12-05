Backbone.Model.prototype._numSubscribeRequests = 0

Backbone.Model.prototype.subscribe = () ->
	assert.ok @urlRoot? and @id? and @onUpdate?
	@_numSubscribeRequests++

	socket.emit @urlRoot + ':subscribe', id: @id, (error, result) =>
		if error?
			console.error error
			return

		assert.ok result.eventName? and result.eventName isnt ''
		console.log 'socket.on ' + result.eventName
		socket.on result.eventName, (data) =>
			console.log data
			assert.ok data.type?
			@onUpdate data


Backbone.Model.prototype.unsubscribe = () ->
	assert.ok @urlRoot? and @id?
	@_numSubscribeRequests--

	if @_numSubscribeRequests is 0
		console.log 'is there a socket.off ??'
		socket.emit @urlRoot + ':unsubscribe', id: @id


Backbone.View.prototype.dispose = () ->
	@remove()
	@unbind()
	@onDispose() if @onDispose?
	return
	
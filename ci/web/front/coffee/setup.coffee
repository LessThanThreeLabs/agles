Backbone.Model.prototype._numSubscribeRequests = 0

Backbone.Model.prototype.subscribe = () ->
	assert.ok @subscribeUrl?
	assert.ok @subscribeId?
	assert.ok @onUpdate?

	@_numSubscribeRequests++

	console.log 'subscribing to ' + @subscribeUrl + ':subscribe' + '   id: ' + @subscribeId
	socket.emit @subscribeUrl + ':subscribe', id: @subscribeId, (error, result) =>
		if error?
			console.error error
			return

		assert.ok result.eventName? 
		assert.ok result.eventName isnt ''

		socket.on result.eventName, (data) =>
			assert.ok data.type?
			@onUpdate data


Backbone.Model.prototype.unsubscribe = () ->
	assert.ok @subscribeUrl?
	assert.ok @subscribeId?
	assert.ok @_numSubscribeRequests > 0

	@_numSubscribeRequests--
	if @_numSubscribeRequests is 0
		console.log 'unsubscribing from ' + @subscribeUrl + ':subscribe' + '   id: ' + @subscribeId
		socket.emit @subscribeUrl + ':unsubscribe', id: @subscribeId


Backbone.View.prototype.dispose = () ->
	@remove()
	@unbind()
	@onDispose() if @onDispose?
	return
	
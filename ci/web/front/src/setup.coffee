Backbone.Model.prototype._numSubscribeRequests = 0
Backbone.Model.prototype._currentEventName = null


Backbone.Model.prototype.subscribe = () ->
	assert.ok @subscribeUrl?
	assert.ok @subscribeId?
	assert.ok @onUpdate?

	@_numSubscribeRequests++

	socket.emit @subscribeUrl + ':subscribe', id: @subscribeId, (error, result) =>
		if error?
			console.error error
			return

		assert.ok result.eventName? 
		assert.ok result.eventName isnt ''

		@_currentEventName = result.eventName
		socket.on result.eventName, (data) =>
			assert.ok data.type?

			console.log 'received event for room ' + result.eventName + ':'
			console.log data

			if result.eventName is @_currentEventName
				@onUpdate data
			else
				console.error 'Unexpected event!'
				console.log '...maybe the room name changed in between subscribe() calls?'


Backbone.Model.prototype.unsubscribe = () ->
	assert.ok @subscribeUrl?
	assert.ok @subscribeId?
	assert.ok @_numSubscribeRequests > 0

	@_numSubscribeRequests--
	if @_numSubscribeRequests is 0
		socket.emit @subscribeUrl + ':unsubscribe', id: @subscribeId


Backbone.View.prototype.dispose = () ->
	@remove()
	@unbind()
	@onDispose() if @onDispose?
	return
	
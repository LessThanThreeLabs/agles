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

			if result.eventName is @_currentEventName
				@onUpdate data
			else
				console.log 'Unexpected event!'
				console.leg '  this really isnt a surprise... but I wanted to see if it would ever happen'


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
	
Backbone.Model.prototype._subscribed = false
Backbone.Model.prototype._currentEventName = null


Backbone.Model.prototype.subscribe = () ->
	assert.ok @subscribeUrl?
	assert.ok @subscribeId?
	assert.ok @onUpdate?
	assert.ok not @_subscribed

	@_subscribed = true
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
				console.error 'Unexpected event for room: ' + result.eventName
				console.error data
				console.log '...maybe the room name changed in between subscribe() calls?'


Backbone.Model.prototype.unsubscribe = () ->
	assert.ok @subscribeUrl?
	assert.ok @subscribeId?
	assert.ok @_subscribed

	@_subscribed = false
	socket.emit @subscribeUrl + ':unsubscribe', id: @subscribeId


Backbone.View.prototype.dispose = () ->
	@remove()
	@unbind()
	@onDispose() if @onDispose?
	return
	
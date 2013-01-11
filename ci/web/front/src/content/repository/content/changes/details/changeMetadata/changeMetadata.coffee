window.ChangeMetadata = {}


class ChangeMetadata.Model extends Backbone.Model
	defaults:
		submitter: ''


	initialize: () =>


	fetchMetadata: () =>
		# socket.emit 'buildOutputs:read', id: @get('id'), (error, result) =>
		# 	if error?
		# 		globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
		# 		console.error error
		# 	else
		# 		@_addInitialLines result.consoleOutput



class ChangeMetadata.View extends Backbone.View
	tagName: 'div'
	className: 'changeMetadata'
	html: 'hello there'


	initialize: () =>
		# @model.on 'change:lines', @_addInitialLines, @
		# @model.on 'lineUpdated', @_handleLineUpdated, @
		# @model.on 'lineAdded', @_handleAddLine, @

		# @model.subscribe()
		# @model.fetchOutput()


	onDispose: () =>
		# @model.off null, null, @
		# @model.unsubscribe()


	render: () =>
		@$el.html @html 
		return @

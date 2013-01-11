window.ChangeMetadata = {}


class ChangeMetadata.Model extends Backbone.Model
	defaults:
		submitter: ''


	initialize: () =>


	fetchMetadata: () =>
		requestData =
			method: 'getChangeMetadata'
			args: id: globalRouterModel.get('changeId')

		socket.emit 'changes:read', requestData, (error, changeMetadata) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error error
			else
				console.log changeMetadata


class ChangeMetadata.View extends Backbone.View
	tagName: 'div'
	className: 'changeMetadata'
	html: 'hello there'


	initialize: () =>
		# @model.on 'change:lines', @_addInitialLines, @
		# @model.on 'lineUpdated', @_handleLineUpdated, @
		# @model.on 'lineAdded', @_handleAddLine, @

		@model.fetchMetadata()


	onDispose: () =>


	render: () =>
		@$el.html @html 
		return @

window.RepositoryHeader = {}


class RepositoryHeader.Model extends Backbone.Model
	default:
		repositoryId: null
		name: ''
		description: ''

	initialize: () =>
		@on 'change:repositoryId', @_getNameAndDescription


	validate: (attributes) =>
		if not attributes.repositoryId? or not attributes.name? or not attributes.description?
			return false
		return


	_getNameAndDescription: () =>
		requestData = id: @get 'repositoryId'
		socket.emit 'repositories:read', requestData, (error, data) =>
			console.error error if error?
			@set data if data?


class RepositoryHeader.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeader'
	template: Handlebars.compile '<div class="repositoryHeaderContents">
			<div class="repositoryName">{{name}}</div>
			<div class="repositorySubname">{{subname}}</div>
		</div>'

	initialize: () =>
		@model.on 'change:name', @render
		@model.on 'change:description', @render


	render: () =>
		@$el.html @template
			name: @model.get 'name'
			description: @model.get 'description'
		return @

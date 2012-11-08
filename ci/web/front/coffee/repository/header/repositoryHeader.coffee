window.RepositoryHeader = {}


class RepositoryHeader.Model extends Backbone.Model
	default:
		repositoryId: null
		name: 'test'
		description: 'test'
		url: 'test'

	initialize: () =>
		@on 'change:repositoryId', () =>
			@_getNameAndDescription()


	validate: (attributes) =>
		if not attributes.repositoryId?
			return new Error 'Invalid repository id'

		if attributes.name? and attributes.name.length is 0
			return new Error 'Invalid repository name'

		if attributes.description? and attributes.description.length is 0
			return new Error 'Invalid repository description'

		if attributes.url? and attributes.url.length is 0
			return new Error 'Invalid repository url'

		return


	_getNameAndDescription: () =>
		requestData = id: @get 'repositoryId'
		socket.emit 'repositories:read', requestData, (error, data) =>
			console.error error if error?
			console.log data
			@set data if data?


class RepositoryHeader.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeader'
	template: Handlebars.compile '<div class="repositoryNameAndDescription">
			<div class="repositoryName">{{name}}</div>
			<div class="repositoryDescription">{{description}}</div>
		</div>
		<div class="repositoryUrlContainer">
			<span class="repositoryUrlLabel">Url:</span><input type="text" class="repositoryUrl" value="{{url}}" readonly>
		</div>'

	initialize: () =>
		@model.on 'change:name', @render
		@model.on 'change:description', @render


	render: () =>
		@$el.html @template
			name: @model.get 'name'
			description: @model.get 'description'
			url: @model.get 'url'
		return @

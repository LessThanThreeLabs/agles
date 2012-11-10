window.RepositoryHeaderBasicInformation = {}


class RepositoryHeaderBasicInformation.Model extends Backbone.Model
	default:
		repositoryId: null
		name: ''
		description: ''

	initialize: () =>

	validate: (attributes) =>
		if attributes.name? and attributes.name.length is 0
			return new Error 'Invalid repository name'

		if attributes.description? and attributes.description.length is 0
			return new Error 'Invalid repository description'

		return


class RepositoryHeaderBasicInformation.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeaderBasicInformation'
	template: Handlebars.compile '<span class="repositoryName">> {{name}}</span><br>
			<span class="repositoryDescription">{{description}}</span>'

	initialize: () =>
		@model.on 'change:name', @render
		@model.on 'change:description', @render


	render: () =>
		@$el.html @template
			name: @model.get 'name'
			description: @model.get 'description'
		return @

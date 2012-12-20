window.RepositoryHeaderBasicInformation = {}


class RepositoryHeaderBasicInformation.Model extends Backbone.Model
	default:
		name: ''
		description: ''


	validate: (attributes) =>
		if typeof attributes.name isnt 'string' or attributes.name.length is 0
			return new Error 'Invalid repository name: ' + attributes.name

		if typeof attributes.description isnt 'string' or attributes.description.length is 0
			return new Error 'Invalid repository description: ' + attributes.description

		return


class RepositoryHeaderBasicInformation.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeaderBasicInformation'
	template: Handlebars.compile '<div class="repositoryName">> {{name}}</div>
			<div class="repositoryDescription">{{description}}</div>'


	initialize: () =>
		@model.on 'change:name change:description', @render, @


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @template
			name: @model.get 'name'
			description: @model.get 'description'
		return @

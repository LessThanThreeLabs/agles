window.RepositoryHeader = {}


class RepositoryHeader.Model extends Backbone.Model

	initialize: () ->


class RepositoryHeader.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeader'
	template: Handlebars.compile '<div class="repositoryHeaderContents">
			<div class="repositoryName">{{name}}</div>
			<div class="repositorySubname">{{subname}}</div>
		</div>'

	initialize: () =>
		@model.on 'change:name', @render
		@model.on 'change:subname', @render


	render: () =>
		@$el.html @template
			name: @model.get 'name'
			subname: @model.get 'subname'
		return @

window.RepositoryUrlPanel = {}


class RepositoryUrlPanel.Model extends Backbone.Model
	default:
		url: null

	initialize: () =>

	validate: (attributes) =>
		if not attributes.url? or attributes.url.length is 0
			return new Error 'Invalid repository url'

		return


class RepositoryUrlPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryUrlPanel'
	template: Handlebars.compile '<div class="relativePositionWrapper">
			<img src="/img/icons/link.svg" class="repositoryLinkImage"><div class="repositoryUrl">{{url}}</div>
		</div>'

	initialize: () =>
		@model.on 'change:url', @render


	render: () =>
		@$el.html @template url: @model.get 'url'
		return @

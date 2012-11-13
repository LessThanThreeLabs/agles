window.RepositoryUrlTrinket = {}


class RepositoryUrlTrinket.Model extends Backbone.Model
	defaults:
		url: ''

	initialize: () =>

	validate: (attributes) =>
		if not attributes.url? or attributes.url.length is 0
			return new Error 'Invalid repository url'

		return


class RepositoryUrlTrinket.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryUrlTrinket'
	template: Handlebars.compile '<img src="/img/icons/link.svg" class="repositoryUrlImage">
		<div class="repositoryUrlTooltip">
			git clone <span class="repositoryUrl">{{url}}</span>
		</div>'

	initialize: () =>
		@model.on 'change:url', @render


	render: () =>
		@$el.html @template url: @model.get 'url'
		Tipped.create @$el.find('.repositoryUrlImage'), @$el.find('.repositoryUrlTooltip')[0], skin: 'default'
		return @

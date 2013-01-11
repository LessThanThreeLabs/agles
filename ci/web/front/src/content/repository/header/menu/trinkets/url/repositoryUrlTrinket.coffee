window.RepositoryUrlTrinket = {}


class RepositoryUrlTrinket.Model extends Backbone.Model
	defaults:
		url: ''


	validate: (attributes) =>
		if typeof attributes.url isnt 'string' or attributes.url.length is 0
			return new Error 'Invalid repository url: ' + attributes.url
		return


class RepositoryUrlTrinket.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryUrlTrinket'
	template: Handlebars.compile '<img src="/img/icons/link' + filesSuffix + '.svg" class="repositoryUrlImage">
		<div class="repositoryUrlTooltip">
			git clone <span class="repositoryUrl">{{url}}</span>
		</div>'


	initialize: () =>
		@model.on 'change:url', @render, @


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @template url: @model.get 'url'
		Tipped.create @$('.repositoryUrlImage'), @$('.repositoryUrlTooltip')[0], skin: 'default'
		return @

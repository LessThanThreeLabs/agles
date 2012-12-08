window.RepositoryUrlTrinket = {}


class RepositoryUrlTrinket.Model extends Backbone.Model
	defaults:
		url: ''


	fetchRepositoryCloneUrl: () =>
		@clear()

		return if not globalRouterModel.get('repositoryId')?

		requestData =
			method: 'getCloneUrl'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'

		socket.emit 'repos:read', requestData, (error, url) =>
			if error?
				console.error error
			else
				@set 'url', url


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
		@model.on 'change:url', @render, @
		globalRouterModel.on 'change:repositoryId', @model.fetchRepositoryCloneUrl, @
		@model.fetchRepositoryCloneUrl()


	onDispose: () =>
		@model.off null, null, @
		globalRouterModel.off null, null, @

	render: () =>
		@$el.html @template url: @model.get 'url'
		Tipped.create @$el.find('.repositoryUrlImage'), @$el.find('.repositoryUrlTooltip')[0], skin: 'default'
		return @

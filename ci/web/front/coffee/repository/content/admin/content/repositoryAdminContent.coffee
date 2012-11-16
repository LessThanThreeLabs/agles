window.RepositoryAdminContent = {}


class RepositoryAdminContent.Model extends Backbone.Model
	defaults:
		repositoryId: null
		mode: null

	initialize: () ->


class RepositoryAdminContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminContent'

	initialize: () ->
		@model.on 'change:mode', @render


	render: () ->
		# @_renderCurrentView()
		@$el.html 'hello'
		return @


	_renderCurrentView: () =>
		switch @model.get 'mode'
			when 'general'
				console.log 'general'
				# repositoryBuildsView = new RepositoryBuilds.View model: @model.repositoryBuildsModel
				# @$el.html repositoryBuildsView.render().el
			when 'members'
				console.log 'members'
				# repositoryAdminView = new RepositoryAdmin.View model: @model.repositoryAdminModel
				# @$el.html repositoryAdminView.render().el
			else
				console.error 'Unaccounted for mode ' + @model.get 'mode' if @model.get('mode')?

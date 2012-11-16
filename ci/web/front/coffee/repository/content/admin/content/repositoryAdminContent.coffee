window.RepositoryAdminContent = {}


class RepositoryAdminContent.Model extends Backbone.Model
	defaults:
		repositoryId: null
		mode: null

	initialize: () ->
		@generalPanelModel = new RepositoryAdminGeneralPanel.Model()


class RepositoryAdminContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminContent'

	initialize: () =>
		@model.on 'change:mode', @render


	render: () =>
		@_renderCurrentView()
		return @


	_renderCurrentView: () =>
		switch @model.get 'mode'
			when 'general'
				generalPanelView = new RepositoryAdminGeneralPanel.View model: @model.generalPanelModel
				@$el.html generalPanelView.render().el
			# when 'members'
			# 	console.log 'members'
				# repositoryAdminView = new RepositoryAdmin.View model: @model.repositoryAdminModel
				# @$el.html repositoryAdminView.render().el
			else
				@$el.html '&nbsp'
				console.error 'Unaccounted for mode ' + @model.get 'mode' if @model.get('mode')?

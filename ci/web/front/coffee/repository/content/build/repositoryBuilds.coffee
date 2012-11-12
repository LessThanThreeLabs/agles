window.RepositoryBuilds = {}


class RepositoryBuilds.Model extends Backbone.Model

	initialize: () ->
		@buildsListManagerModel = new BuildsListManager.Model repositoryId: @get 'repositoryId'
		# @buildDetailsModel = new BuildDetails.Model repositoryId: @get 'repositoryId'

		# @buildsListManagerModel.on 'selectedBuild', @_handleSelectedBuild


	# _handleSelectedBuild: (buildModel) =>
		# @buildDetailsModel.set 'build', buildModel


class RepositoryBuilds.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryBuilds'
	template: Handlebars.compile ''

	initialize: () ->
		# @buildsListManagerView = new BuildsListManager.View model: @model.buildsListManagerModel
		# @buildDetailsView = new BuildDetails.View model: @model.buildDetailsModel


	render: () ->
		@$el.html @template()
		buildsListManagerView = new BuildsListManager.View model: @model.buildsListManagerModel
		@$el.append buildsListManagerView.render().el
		# @$el.find('.repositoryBuildsContents').append @buildDetailsView.render().el
		return @

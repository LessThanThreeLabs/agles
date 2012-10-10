window.Repository = {}


class Repository.Model extends Backbone.Model
	urlRoot: 'repositories'

	initialize: () ->
		@repositoryHeaderModel = new RepositoryHeader.Model repositoryId: @get 'id'
		@buildsListManagerModel = new BuildsListManager.Model repositoryId: @get 'id'
		@buildDetailsModel = new BuildDetails.Model repositoryId: @get 'id'

		@buildsListManagerModel.on 'selectedBuild', @_handleSelectedBuild

		@on 'change', () =>
			@repositoryHeaderModel.set 'name', @get 'name'
			@repositoryHeaderModel.set 'subname', @get 'subname'


	_handleSelectedBuild: (buildModel) =>
		@buildDetailsModel.set 'build', buildModel


class Repository.View extends Backbone.View
	tagName: 'div'
	className: 'repository'
	template: Handlebars.compile ''

	initialize: () ->
		@repositoryHeaderView = new RepositoryHeader.View model: @model.repositoryHeaderModel
		@buildsListManagerView = new BuildsListManager.View model: @model.buildsListManagerModel
		@buildDetailsView = new BuildDetails.View model: @model.buildDetailsModel


	render: () ->
		@$el.html @template()
		@$el.append @repositoryHeaderView.render().el
		@$el.append @buildsListManagerView.render().el
		@$el.append @buildDetailsView.render().el
		return @




repositoryModel = new Repository.Model id: Math.floor Math.random() * 10000
repositoryModel.fetch()

repositoryView = new Repository.View model: repositoryModel
$('#mainContainer').append repositoryView.render().el

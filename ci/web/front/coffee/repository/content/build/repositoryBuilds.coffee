window.RepositoryBuilds = {}


class RepositoryBuilds.Model extends Backbone.Model
	default:
		repositoryId: null
		selectedBuildId: null

	initialize: () ->
		@buildsListManagerModel = new BuildsListManager.Model repositoryId: @get 'repositoryId'
		@buildDetailsModel = new BuildDetails.Model repositoryId: @get 'repositoryId'

		@buildsListManagerModel.on 'selectedBuild', (buildModel) =>
			@set 'selectedBuildId', buildModel?.get 'id'

		@on 'change:repositoryId', () =>
			@buildsListManagerModel.set 'repositoryId', @get 'repositoryId'
			@buildDetailsModel.set 'repositoryId', @get 'repositoryId'

		@on 'change:selectedBuildId', () =>
			@buildDetailsModel.set 'buildId', @get 'selectedBuildId'


class RepositoryBuilds.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryBuilds'
	template: Handlebars.compile ''

	initialize: () ->

	render: () ->
		@$el.html @template()

		buildsListManagerView = new BuildsListManager.View model: @model.buildsListManagerModel
		@$el.append buildsListManagerView.render().el

		buildDetailsView = new BuildDetails.View model: @model.buildDetailsModel
		@$el.append buildDetailsView.render().el
		return @

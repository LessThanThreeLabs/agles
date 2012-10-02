window.BuildsListManager = {}


class BuildsListManager.Model extends Backbone.Model

	initialize: () ->
		@buildsFetcher = new BuildsFetcher()

		@allBuildsListModel = new BuildsList.Model
			repositoryId: @get 'repositoryId'
			buildsFetcher: @buildsFetcher
			type: 'all'


class BuildsListManager.View extends Backbone.View
	tagName: 'div'
	className: 'buildsListManager'
	template: Handlebars.compile ''

	initialize: () ->
		@allBuildsListView = new BuildsList.View model: @model.allBuildsListModel
		@allBuildsListView.loadInitialBuilds(40, 20)


	render: () ->
		@$el.html @template()
		@$el.append @allBuildsListView.render().el
		return @

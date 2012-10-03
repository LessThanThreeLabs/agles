window.BuildsListManager = {}


class BuildsListManager.Model extends Backbone.Model

	initialize: () =>
		@buildsFetcher = new BuildsFetcher()
		@buildsSearchModel = new BuildsSearch.Model()

		@allBuildsListModel = new BuildsList.Model
			repositoryId: @get 'repositoryId'
			buildsFetcher: @buildsFetcher
			type: 'all'

		@userBuildsListModel = new BuildsList.Model
			repositoryId: @get 'repositoryId'
			buildsFetcher: @buildsFetcher
			type: 'user'

		@criticalBuildsListModel = new BuildsList.Model
			repositoryId: @get 'repositoryId'
			buildsFetcher: @buildsFetcher
			type: 'critical'


class BuildsListManager.View extends Backbone.View
	tagName: 'div'
	className: 'buildsListManager'
	template: Handlebars.compile ''

	initialize: () =>
		@buildsSearchView = new BuildsSearch.View model: @model.buildsSearchModel

		@allBuildsListView = new BuildsList.View model: @model.allBuildsListModel
		@userBuildsListView = new BuildsList.View model: @model.userBuildsListModel
		@criticalBuildsListView = new BuildsList.View model: @model.criticalBuildsListModel


	render: () =>
		@$el.html @template()

		@$el.append @buildsSearchView.render().el

		@$el.append '<div class="buildsListContainer"></div>'
		@$el.find('.buildsListContainer').append @allBuildsListView.render().el
		@allBuildsListView.saturateBuilds()

		return @

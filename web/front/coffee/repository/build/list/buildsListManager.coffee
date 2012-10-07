window.BuildsListManager = {}


class BuildsListManager.Model extends Backbone.Model

	initialize: () =>
		@buildsSearchModel = new BuildsSearch.Model()
		@buildsSearchModel.on 'selectedFilterType', (filterType) =>
			@set 'currentBuildsList', @_getBuildListFromType filterType

		@buildsListModels = []
		filterTypes = @buildsSearchModel.buildsSearchFilterModel.buildsSearchFilterSelectorModel.types
		for filterType in filterTypes
			@buildsListModels.push new BuildsList.Model
				repositoryId: @get 'repositoryId'
				buildsFetcher: new BuildsFetcher()
				type: filterType.name

		currentFilterType = @buildsSearchModel.buildsSearchFilterModel.buildsSearchFilterSelectorModel.get 'selectedType'
		@set 'currentBuildsList', @_getBuildListFromType currentFilterType


	_getBuildListFromType: (type) ->
		for buildsListModel in @buildsListModels
			return buildsListModel if buildsListModel.get('type') is type.name
		return null


	validate: (attributes) =>
		if not attributes.currentBuildsList?
			return new Error 'Invalid current builds list.'

		return


class BuildsListManager.View extends Backbone.View
	tagName: 'div'
	className: 'buildsListManager'
	template: Handlebars.compile ''

	initialize: () =>
		@model.on 'change:currentBuildsList', (filterType) =>
			@_renderBuildsList()

		@buildsSearchView = new BuildsSearch.View model: @model.buildsSearchModel


	render: () =>
		@$el.html @template()

		@$el.append '<div class="buildsSearchContainer"></div>'
		@$el.find('.buildsSearchContainer').append @buildsSearchView.render().el

		@$el.append '<div class="buildsListContainer"></div>'
		@_renderBuildsList()

		return @


	_renderBuildsList: () =>
		buildsListView = new BuildsList.View model: @model.get 'currentBuildsList'
		@$el.find('.buildsListContainer').append buildsListView.render().el
		# buildsListView.saturateBuilds()

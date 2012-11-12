window.BuildsListManager = {}


class BuildsListManager.Model extends Backbone.Model
	default:
		repositoryId: null

	initialize: () =>
		# @buildsSearchModel = new BuildsSearch.Model()
		# @buildsSearchModel.on 'selectedFilterType', (filterType) =>
		# 	console.log 'updated the filter type'
		# 	@get('currentBuildsList').off 'change:selectedBuild', @_handleSelectedBuild
		# 	@set 'currentBuildsList', @_getBuildListFromType filterType
		# 	@get('currentBuildsList').on 'change:selectedBuild', @_handleSelectedBuild
		# @buildsSearchModel.on 'change:queryString', (model, queryString, options) =>
		# 	@get('currentBuildsList').set 'queryString', queryString

		# @buildsListModels = []
		# filterTypes = @buildsSearchModel.buildsSearchFilterModel.buildsSearchFilterSelectorModel.types
		# for filterType in filterTypes
		# 	buildListModel = new BuildsList.Model
		# 		repositoryId: @get 'repositoryId'
		# 		buildsFetcher: new BuildsFetcher()
		# 		type: filterType.name
		# 	buildListModel.fetchInitialBuilds()
		# 	@buildsListModels.push buildListModel

		# currentFilterType = @buildsSearchModel.buildsSearchFilterModel.buildsSearchFilterSelectorModel.get 'selectedType'
		# @set 'currentBuildsList', @_getBuildListModelFromType currentFilterType
		# @get('currentBuildsList').on 'change:selectedBuild', @_handleSelectedBuild

		@buildsListModel = new BuildsList.Model repositoryId: @get 'repositoryId'

		# TEMPORARY!!
		@buildsListModel.set 'listType', 'all'

		@on 'change:repositoryId', () =>
			@buildsListModel.set 'repositoryId', @get 'repositoryId'


	# _getBuildListModelFromType: (type) ->
	# 	for buildsListModel in @buildsListModels
	# 		return buildsListModel if buildsListModel.get('type') is type.name
	# 	return null


	# _handleSelectedBuild: (buildsListModel, buildModel) =>
	# 	@trigger 'selectedBuild', buildModel


	# validate: (attributes) =>
	# 	if not attributes.currentBuildsList?
	# 		return new Error 'Invalid current builds list.'

	# 	return


class BuildsListManager.View extends Backbone.View
	tagName: 'div'
	className: 'buildsListManager'
	template: Handlebars.compile '<div class="buildsListManagerContainer">
			<div class="buildsSearchContainer"></div>
			<div class="buildsListContainer"></div>
		</div>'

	initialize: () =>

	render: () =>
		@$el.html @template()
		
		# buildsSearchView = new BuildsSearch.View model: @model.buildsSearchModel
		# @$el.find('.buildsSearchContainer').append buildsSearchView.render().el

		buildsListView = new BuildsList.View model: @model.buildsListModel
		@$el.find('.buildsListContainer').html buildsListView.render().el

		return @

window.BuildsListManager = {}


class BuildsListManager.Model extends Backbone.Model
	default:
		repositoryId: null

	initialize: () =>
		@buildsSearchModel = new BuildsSearch.Model()
		@buildsSearchModel.on 'change:queryString', () =>
			@buildsListModel.set 'queryString', @buildsSearchModel.get 'queryString'

		@buildsListModel = new BuildsList.Model repositoryId: @get 'repositoryId'
		@buildsListModel.on 'change:selectedBuild', () =>
			@trigger 'selectedBuild', @buildsListModel.get 'selectedBuild'

		# TEMPORARY!!
		@buildsListModel.set 'listType', 'all'

		@on 'change:repositoryId', () =>
			@buildsListModel.set 'repositoryId', @get 'repositoryId'


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
		
		buildsSearchView = new BuildsSearch.View model: @model.buildsSearchModel
		@$el.find('.buildsSearchContainer').html buildsSearchView.render().el

		buildsListView = new BuildsList.View model: @model.buildsListModel
		@$el.find('.buildsListContainer').html buildsListView.render().el

		return @

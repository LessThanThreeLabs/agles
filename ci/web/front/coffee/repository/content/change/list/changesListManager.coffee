window.BuildsListManager = {}


class BuildsListManager.Model extends Backbone.Model

	initialize: () =>
		@buildsSearchModel = new BuildsSearch.Model()
		@buildsSearchModel.on 'change:queryString', () =>
			@buildsListModel.set 'queryString', @buildsSearchModel.get 'queryString'

		@buildsListModel = new BuildsList.Model()
		@buildsListModel.on 'change:queryString', () =>
			@buildsSearchModel.set 'queryString', @buildsListModel.get 'queryString'


class BuildsListManager.View extends Backbone.View
	tagName: 'div'
	className: 'buildsListManager'
	html: '<div class="buildsListManagerContainer">
			<div class="buildsSearchContainer"></div>
			<div class="buildsListContainer"></div>
		</div>'


	initialize: () =>
		@buildsSearchView = new BuildsSearch.View model: @model.buildsSearchModel
		@buildsListView = new BuildsList.View model: @model.buildsListModel


	onDispose: () =>
		@buildsSearchView.dispose()
		@buildsListView.dispose()


	render: () =>
		@$el.html @html
		@$el.find('.buildsSearchContainer').html @buildsSearchView.render().el
		@$el.find('.buildsListContainer').html @buildsListView.render().el
		return @

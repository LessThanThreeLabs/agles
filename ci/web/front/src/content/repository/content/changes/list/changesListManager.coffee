window.ChangesListManager = {}


class ChangesListManager.Model extends Backbone.Model

	initialize: () =>
		@changesListSearchModel = new ChangesListSearch.Model()
		@changesListSearchModel.on 'change:queryString', () =>
			@changesListModel.set 'queryString', @changesListSearchModel.get 'queryString'

		@changesListModel = new ChangesList.Model()
		@changesListModel.on 'change:queryString', () =>
			@changesListSearchModel.set 'queryString', @changesListModel.get 'queryString'


class ChangesListManager.View extends Backbone.View
	tagName: 'div'
	className: 'changesListManager'
	html: '<div class="changesListManagerContainer">
			<div class="changesSearchContainer"></div>
			<div class="changesListContainer"></div>
		</div>'


	initialize: () =>
		@changesListSearchView = new ChangesListSearch.View model: @model.changesListSearchModel
		@changesListView = new ChangesList.View model: @model.changesListModel


	onDispose: () =>
		@changesListSearchView.dispose()
		@changesListView.dispose()


	render: () =>
		@$el.html @html
		@$('.changesSearchContainer').html @changesListSearchView.render().el
		@$('.changesListContainer').html @changesListView.render().el
		return @

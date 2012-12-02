window.ChangesListManager = {}


class ChangesListManager.Model extends Backbone.Model

	initialize: () =>
		@changesSearchModel = new ChangesSearch.Model()
		@changesSearchModel.on 'change:queryString', () =>
			@changesListModel.set 'queryString', @changesSearchModel.get 'queryString'

		@changesListModel = new ChangesList.Model()
		@changesListModel.on 'change:queryString', () =>
			@changesSearchModel.set 'queryString', @changesListModel.get 'queryString'


class ChangesListManager.View extends Backbone.View
	tagName: 'div'
	className: 'changesListManager'
	html: '<div class="changesListManagerContainer">
			<div class="changesSearchContainer"></div>
			<div class="changesListContainer"></div>
		</div>'


	initialize: () =>
		@changesSearchView = new ChangesSearch.View model: @model.changesSearchModel
		@changesListView = new ChangesList.View model: @model.changesListModel


	onDispose: () =>
		@changesSearchView.dispose()
		@changesListView.dispose()


	render: () =>
		@$el.html @html
		@$el.find('.changesSearchContainer').html @changesSearchView.render().el
		@$el.find('.changesListContainer').html @changesListView.render().el
		return @

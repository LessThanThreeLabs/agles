window.RepositoryChanges = {}


class RepositoryChanges.Model extends Backbone.Model

	initialize: () =>
		@changesListModel = new ChangesList.Model()
		@changeDetailsModel = new ChangeDetails.Model()


class RepositoryChanges.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryChanges'
	html: ''


	initialize: () =>
		@changesListView = new ChangesList.View model: @model.changesListModel
		@changeDetailsView = new ChangeDetails.View model: @model.changeDetailsModel


	onDispose: () =>
		@changesListView.dispose()
		@changeDetailsView.dispose()


	render: () =>
		@$el.html @html
		@$el.append @changesListView.render().el
		@$el.append @changeDetailsView.render().el
		return @

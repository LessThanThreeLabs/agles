window.RepositoryChanges = {}


class RepositoryChanges.Model extends Backbone.Model

	initialize: () =>
		@changesListManagerModel = new ChangesListManager.Model()
		# @changeDetailsModel = new ChangeDetails.Model()


class RepositoryChanges.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryChanges'
	html: ''


	initialize: () =>
		@changesListManagerView = new ChangesListManager.View model: @model.changesListManagerModel
		# @changeDetailsView = new ChangeDetails.View model: @model.changeDetailsModel


	onDispose: () =>
		@changesListManagerView.dispose()
		@changeDetailsView.dispose()


	render: () =>
		@$el.html @html
		@$el.append @changesListManagerView.render().el
		# @$el.append @changeDetailsView.render().el
		return @

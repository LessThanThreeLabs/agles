window.RepositoryChanges = {}


class RepositoryChanges.Model extends Backbone.Model

	initialize: () =>
		@changesListModel = new ChangesList.Model()


class RepositoryChanges.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryChanges'
	html: '<div class="changesListContainer"></div>
		<div class="changeDetailsContainer"></div>'
	currentDetailsView: null


	initialize: () =>
		@changesListView = new ChangesList.View model: @model.changesListModel

		globalRouterModel.on 'change:changeId', @_renderCurrentDetailsView, @


	onDispose: () =>
		globalRouterModel.off null, null, @

		@changesListView.dispose()
		@currentDetailsView.dispose() if @currentDetailsView?


	render: () =>
		@$el.html @html
		@$('.changesListContainer').html @changesListView.render().el
		@_renderCurrentDetailsView()
		return @


	_renderCurrentDetailsView: () =>
		if globalRouterModel.get('changeId')?
			changeDetailsModel = new ChangeDetails.Model()
			@currentDetailsView = new ChangeDetails.View model: changeDetailsModel
			@$('.changeDetailsContainer').html @currentDetailsView.render().el
		else
			@$('.changeDetailsContainer').html 'something cool should go here!!'

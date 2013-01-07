window.ChangesList = {}


class ChangesList.Model extends Backbone.Model
	NUMBER_OF_CHANGES_TO_REQUEST: 100
	noMoreChangesToFetch: false
	subscribeUrl: 'repos'
	subscribeId: null


	initialize: () ->
		@subscribeId = globalRouterModel.get 'repositoryId'

		@changesFetcher = new ChangesFetcher()
		@changesListSearchModel = new ChangesListSearch.Model()
		@changesListSearchModel.on 'change:queryString', @reset

		@changeModels = new Backbone.Collection()
		@changeModels.model = Change.Model
		@changeModels.comparator = (changeModel) =>
			return -1.0 * changeModel.get 'number'

		@changeModels.on 'change:selected', @_handleChangeSelection


	reset: () =>
		@noMoreChangesToFetch = false
		@changeModels.reset()


	_handleChangeSelection: (changeModel) =>
		if changeModel.get 'selected'
			@_deselectAllOtherChangeModels changeModel
			globalRouterModel.set 
				'changeId': changeModel.get 'id'
				'changeView': 'home'
		else
			# we use a timeout here to make sure that we don't set the changeId to null
			# when we're switching between two different change ids
			setTimeout (() =>
				if globalRouterModel.get('changeId') is changeModel.get('id')
					globalRouterModel.set 'changeId', null
				), 0


	_deselectAllOtherChangeModels: (changeModelToExclude) =>
		@changeModels.each (otherChangeModel) =>
			if otherChangeModel.get('id') isnt changeModelToExclude.get('id')
				otherChangeModel.set 'selected', false


	fetchInitialChanges: () =>
		queuePolicy =  ChangesFetcher.QueuePolicy.QUEUE_IF_BUSY
		@_fetchChanges 0, @NUMBER_OF_CHANGES_TO_REQUEST, queuePolicy


	fetchMoreChangesDoNotQueue: () =>
		return if @noMoreChangesToFetch

		queuePolicy =  ChangesFetcher.QueuePolicy.DO_NOT_QUEUE
		@_fetchChanges @changeModels.length, @NUMBER_OF_CHANGES_TO_REQUEST, queuePolicy


	_fetchChanges: (startNumber, numberToRetrieve, queuePolicy) =>
		assert.ok startNumber >= 0
		assert.ok numberToRetrieve > 0
		assert.ok queuePolicy?
		assert.ok not @noMoreChangesToFetch

		changesQuery = new ChangesQuery globalRouterModel.get('repositoryId'),
			@changesListSearchModel.get('queryString'), startNumber, numberToRetrieve

		@changesFetcher.runQuery changesQuery, queuePolicy, (error, result) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error error
			else
				@_processChanges numberToRetrieve, result


	_processChanges: (numberResultsExpecting, result) =>
		# it's possible this is being called for an old query
		return if result.queryString isnt @changesListSearchModel.get 'queryString'

		# if we didn't receive as many changes as we were 
		# expecting, we must have reached the end
		@noMoreChangesToFetch = result.changes.length < numberResultsExpecting

		@changeModels.add result.changes


	onUpdate: (data) =>
		if data.type is 'change added'
			changeModel = new Change.Model
				id: data.contents.id
				number: data.contents.number
				status: data.contents.status
			@changeModels.add changeModel


class ChangesList.View extends Backbone.View
	HEIGHT_BEFORE_FETCHING_MORE_CHANGES: 200
	tagName: 'div'
	className: 'changesList'
	html: '<div class="changesListSearchContainer"></div>
		<div class="changesListPanel">
			<div class="changesListPanelContainer"></div>
		</div>'
	events:	'scroll': '_scrollHandler'
	changeViews: []


	initialize: () =>
		@changesListSearchView = new ChangesListSearch.View model: @model.changesListSearchModel

		@model.changeModels.on 'add', @_handleAddedChange, @
		@model.changeModels.on 'reset', @_handleChangesReset, @

		@model.subscribeId = globalRouterModel.get 'repositoryId'
		@model.subscribe()
		@model.fetchInitialChanges()


	onDispose: () =>
		@model.unsubscribe() if @model.subscribeId?
		@model.changeModels.off null, null, @
		globalRouterModel.off null, null, @

		@_disposeAllChanges()
		@changesListSearchView.dispose()


	render: () =>
		@$el.html @html
		@$('.changesListSearchContainer').html @changesListSearchView.render().el
		@_renderInitialChanges()
		return @


	_renderInitialChanges: () =>
		@model.changeModels.each (changeModel) =>
			changeView = new Change.View model: changeModel
			@changeViews.push changeView
			@$('.changesListPanelContainer').append changeView.render().el


	_disposeAllChanges: () =>
		for changeView in @changeViews
			changeView.dispose()
		@changeViews = []


	_scrollHandler: () =>
		if @el.scrollTop + @el.clientHeight + @HEIGHT_BEFORE_FETCHING_MORE_CHANGES > @el.scrollHeight
			@model.fetchMoreChangesDoNotQueue()


	_handleAddedChange: (changeModel, collection, options) =>
		changeView = new Change.View model: changeModel
		@changeViews.push changeView
		@_insertChangeAtIndex changeView.render().el, options.index


	_insertChangeAtIndex: (changeView, index) =>
		if index == 0
			@$('.changesListPanelContainer').prepend changeView
		else 
			@$('.change:nth-child(' + index + ')').after changeView


	_handleChangesReset: () =>
		@_disposeAllChanges()
		@$('.changesListPanelContainer').empty()
		@model.fetchInitialChanges()

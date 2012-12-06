window.ChangesList = {}


class ChangesList.Model extends Backbone.Model
	NUMBER_OF_CHANGES_TO_REQUEST: 100
	noMoreChangesToFetch: false
	subscribeUrl: 'repos'
	subscribeId: null
	defaults:
		queryString: ''


	initialize: () ->
		@subscribeId = globalRouterModel.get 'repositoryId'
		@changesFetcher = new ChangesFetcher()

		@changeModels = new Backbone.Collection()
		@changeModels.model = Change.Model
		@changeModels.comparator = (changeModel) =>
			return -1.0 * changeModel.get 'number'

		@changeModels.on 'change:selected', @_handleChangeSelection


	_handleChangeSelection: (changeModel) =>
		if changeModel.get 'selected'
			@_deselectAllOtherChangeModels changeModel
			globalRouterModel.set 
				'changeId': changeModel.get 'id'
				'changeView': 'compilation'
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


	resetChangesList: () =>
		@noMoreChangesToFetch = false
		@changeModels.reset()


	fetchInitialChanges: () =>
		return if not globalRouterModel.get('repositoryId')?

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

		changesQuery = new ChangesQuery globalRouterModel.get('repositoryId'), @get('queryString'), startNumber, numberToRetrieve
		@changesFetcher.runQuery changesQuery, queuePolicy, (error, result) =>
			if error?
				console.error error
				return

			# It's possible this is being called for an old query
			return if result.queryString isnt @get 'queryString'

			# If we didn't receive as many changes as we were 
			#   expecting, we must have reached the end.
			@noMoreChangesToFetch = result.changes.length < numberToRetrieve

			@changeModels.add result.changes


	onUpdate: (data) =>
		if data.type is 'change added'
			changeModel = new Change.Model
				id: data.contents.id
				number: data.contents.number
				status: data.contents.status
			@changeModels.add changeModel


class ChangesList.View extends Backbone.View
	tagName: 'div'
	className: 'changesList'
	html: '&nbsp'
	events:	'scroll': '_scrollHandler'


	initialize: () =>
		@model.on 'change:queryString', @model.resetChangesList, @

		@model.changeModels.on 'add', @_handleAddedChange, @
		@model.changeModels.on 'reset', (() =>
			@$el.empty()
			@model.fetchInitialChanges()
			), @

		globalRouterModel.on 'change:repositoryId', (() =>
			@model.unsubscribe() if @model.subscribeId?
			@model.subscribeId = globalRouterModel.get 'repositoryId'
			@model.subscribe() if @model.subscribeId?
			@model.resetChangesList()
			), @

		@model.subscribeId = globalRouterModel.get 'repositoryId'
		@model.subscribe() if @model.subscribeId?
		@model.resetChangesList()


	onDispose: () =>
		@model.off null, null, @
		@model.unsubscribe() if @model.subscribeId?
		@model.changeModels.off null, null, @
		globalRouterModel.off null, null, @

		@model.resetChangesList()


	render: () =>
		@$el.html @html
		@_renderInitialChanges()
		return @


	_renderInitialChanges: () =>
		@model.changeModels.each (changeModel) =>
			changeView = new Change.View model: changeModel
			@$el.append changeView.render().el


	_scrollHandler: () =>
		heightBeforeFetchingMoreChanges = 200
		if @el.scrollTop + @el.clientHeight + heightBeforeFetchingMoreChanges > @el.scrollHeight
			@model.fetchMoreChangesDoNotQueue()


	_handleAddedChange: (changeModel, collection, options) =>
		changeView = new Change.View model: changeModel
		@_insertChangeAtIndex changeView.render().el, options.index


	_insertChangeAtIndex: (changeView, index) =>
		if index == 0
			@$el.prepend changeView
		else 
			@$el.find('.change:nth-child(' + index + ')').after changeView

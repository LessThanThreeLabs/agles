window.BuildsList = {}


class BuildsList.Model extends Backbone.Model
	defaults:
		queryString: ''

	initialize: () ->
		@buildModels = new Backbone.Collection
		@buildModels.model = Build.Model
		@buildModels.comparator = (buildModel) =>
			return -1.0 * buildModel.get 'number'

		@buildModels.on 'add', (buildModel, collection, options) =>
			@trigger 'add', buildModel, collection, options
		@buildModels.on 'reset', () =>
			@trigger 'reset'
		@buildModels.on 'change:selected', (buildModel) =>
			@_deselectAllBuildModels buildModel

		@on 'change:queryString', @_resetBuildsList

		@_fetchInitialBuilds()


	_deselectAllBuildModels: (buildModelToExclude) =>
		return if not buildModelToExclude.get 'selected'
		@buildModels.each (otherBuildModel) =>
			if otherBuildModel.id isnt buildModelToExclude.id
				otherBuildModel.set 'selected', false


	_resetBuildsList: () =>
		@buildModels.reset()
		@_fetchInitialBuilds()


	_numberOfBuildsToRequest: 50
	noMoreBuildsToFetch = false
	_fetchInitialBuilds: () =>
		@_fetchBuilds 0, @_numberOfBuildsToRequest, BuildsFetcher.QueuePolicy.QUEUE_IF_BUSY


	fetchMoreBuildsDoNotQueue: (callback) =>
		console.log 'called!'
		@_fetchBuilds @buildModels.length, @buildModels.length + @_numberOfBuildsToRequest, BuildsFetcher.QueuePolicy.DO_NOT_QUEUE, callback


	_fetchBuilds: (start, end, queuePolicy, callback) =>
		assert.ok start < end and queuePolicy? and not @noMoreBuildsToFetch

		currentType = @get('type')
		currentQueryString = @get('queryString')
		buildsQuery = new BuildsQuery @get('repositoryId'), currentType, currentQueryString, start, end
		@get('buildsFetcher').runQuery buildsQuery, queuePolicy, (error, buildsData) =>
			if error? 
				console.error 'Error when retrieving builds ' + error
				return

			# It's possible this is being called for an old query
			return if currentType is not @get('type') or currentQueryString is not @get('queryString')

			# If we didn't receive as many builds as we were 
			#   expecting, we must have reached the end.
			@noMoreBuildsToFetch = (end - start > buildsData.length)

			@buildModels.add buildsData
			callback() if callback?


class BuildsList.View extends Backbone.View
	tagName: 'div'
	className: 'buildsList'
	template: Handlebars.compile ''
	events:
		'scroll': '_scrollHandler'

	initialize: () =>
		@model.on 'add', @_handleAdd
		@model.on 'reset', @_handleReset
		$(window).bind 'resize', @_windowResizeHandler


	render: () =>
		@$el.html @template()
		@model.buildModels.each (buildModel) =>
			buildView = new Build.View model: buildModel
			@$el.append buildView.render().el
		return @


	_loadBuildsToFitHeight: () =>
		console.log 'called ' + @model.get 'type'
		if not @model.noMoreBuildsToFetch and 
				(@el.scrollHeight < @el.clientHeight * 2 or @model.buildModels.length is 0)
			@model.fetchMoreBuildsDoNotQueue () =>
				@_loadBuildsToFitHeight()


	_scrollHandler: () =>
		heightBeforeFetchingMoreBuilds = 100
		if @el.scrollTop + @el.clientHeight + heightBeforeFetchingMoreBuilds > @el.scrollHeight
			@model.fetchMoreBuildsDoNotQueue()


	_windowResizeHandler: () =>
		@_loadBuildsToFitHeight


	_handleAdd: (buildModel, collection, options) =>
		buildView = new Build.View model: buildModel
		@_insertBuildAtIndex buildView.render().el, options.index


	_insertBuildAtIndex: (buildView, index) =>
		if index == 0 then $('.buildsList').prepend buildView
		else $('.buildsList .build:nth-child(' + index + ')').after buildView


	_handleReset: () =>
		console.log 'reset event!'

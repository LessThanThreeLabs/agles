window.BuildsList = {}


class BuildsList.Model extends Backbone.Model
	NUMBER_OF_BUILDS_TO_REQUEST: 100
	noMoreBuildsToFetch: false
	defaults:
		queryString: ''


	initialize: () ->
		@buildsFetcher = new BuildsFetcher()

		@buildModels = new Backbone.Collection()
		@buildModels.model = Build.Model
		@buildModels.comparator = (buildModel) =>
			return -1.0 * buildModel.get 'number'

		@buildModels.on 'change:selected', @_handleBuildSelection

		@on 'change:queryString', () =>
			@_resetBuildsList()
			@fetchInitialBuilds()
		window.globalRouterModel.on 'change:repositoryId', () =>
			@_resetBuildsList()


	_handleBuildSelection: (buildModel) =>
		if buildModel.get 'selected'
			@_deselectAllOtherBuildModels buildModel
			window.globalRouterModel.set 'buildId', buildModel.get 'id'
		else
			window.globalRouterModel.set 'buildId', null


	_deselectAllOtherBuildModels: (buildModelToExclude) =>
		@buildModels.each (otherBuildModel) =>
			if otherBuildModel.get('id') isnt buildModelToExclude.get('id')
				otherBuildModel.set 'selected', false


	_resetBuildsList: () =>
		@noMoreBuildsToFetch = false
		@buildModels.reset()


	fetchInitialBuilds: () =>
		queuePolicy =  BuildsFetcher.QueuePolicy.QUEUE_IF_BUSY
		@_fetchBuilds 0, @NUMBER_OF_BUILDS_TO_REQUEST, queuePolicy


	fetchMoreBuildsDoNotQueue: () =>
		return if @noMoreBuildsToFetch

		queuePolicy =  BuildsFetcher.QueuePolicy.DO_NOT_QUEUE
		@_fetchBuilds @buildModels.length, @NUMBER_OF_BUILDS_TO_REQUEST, queuePolicy


	_fetchBuilds: (startNumber, numberToRetrieve, queuePolicy) =>
		assert.ok startNumber >= 0 and numberToRetrieve > 0 and queuePolicy? and not @noMoreBuildsToFetch

		buildsQuery = new BuildsQuery window.globalRouterModel.get('repositoryId'), @get('queryString'), startNumber, numberToRetrieve
		@buildsFetcher.runQuery buildsQuery, queuePolicy, (error, result) =>
			if error?
				console.error error
				return

			# It's possible this is being called for an old query
			return if result.queryString isnt @get 'queryString'

			# If we didn't receive as many builds as we were 
			#   expecting, we must have reached the end.
			@noMoreBuildsToFetch = result.builds.length < numberToRetrieve

			@buildModels.add result.builds, 
				error: (model, error) => 
					console.error error


class BuildsList.View extends Backbone.View
	tagName: 'div'
	className: 'buildsList'
	template: Handlebars.compile ''
	events:
		'scroll': '_scrollHandler'

	initialize: () =>
		@model.buildModels.on 'add', @_handleAddedBuild
		@model.buildModels.on 'reset', () =>
			@$el.empty()


	render: () =>
		@$el.html @template()
		@model.fetchInitialBuilds()
		return @


	_scrollHandler: () =>
		heightBeforeFetchingMoreBuilds = 200
		if @el.scrollTop + @el.clientHeight + heightBeforeFetchingMoreBuilds > @el.scrollHeight
			@model.fetchMoreBuildsDoNotQueue()


	_handleAddedBuild: (buildModel, collection, options) =>
		buildView = new Build.View model: buildModel
		@_insertBuildAtIndex buildView.render().el, options.index


	_insertBuildAtIndex: (buildView, index) =>
		if index == 0 then $('.buildsList').prepend buildView
		else $('.buildsList .build:nth-child(' + index + ')').after buildView

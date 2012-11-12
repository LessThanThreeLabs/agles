window.BuildsList = {}


class BuildsList.Model extends Backbone.Model
	NUMBER_OF_BUILDS_TO_REQUEST: 100
	defaults:
		repositoryId: null
		queryString: ''
		listType: null
		selectedBuild: null

	initialize: () ->
		@buildsFetcher = new BuildsFetcher()

		@buildModels = new Backbone.Collection()
		@buildModels.model = Build.Model
		@buildModels.comparator = (buildModel) =>
			return -1.0 * buildModel.get 'number'

		@buildModels.on 'change:selected', (buildModel) =>
			if buildModel.get 'selected'
				@_deselectAllOtherBuildModels buildModel
				@set 'selectedBuild', buildModel
			else
				@set 'selectedBuild', null

		@on 'change:queryString change:listType change:repositoryId', @_resetBuildsList

		@fetchInitialBuilds()


	_deselectAllOtherBuildModels: (buildModelToExclude) =>
		@buildModels.each (otherBuildModel) =>
			if otherBuildModel.id isnt buildModelToExclude.id
				otherBuildModel.set 'selected', false


	_resetBuildsList: () =>
		@set 'selectedBuild', null
		@buildModels.reset()
		@fetchInitialBuilds()


	noMoreBuildsToFetch: false
	fetchInitialBuilds: () =>
		queuePolicy =  BuildsFetcher.QueuePolicy.QUEUE_IF_BUSY
		@_fetchBuilds 0, @NUMBER_OF_BUILDS_TO_REQUEST, queuePolicy


	fetchMoreBuildsDoNotQueue: () =>
		return if @noMoreBuildsToFetch

		queuePolicy =  BuildsFetcher.QueuePolicy.DO_NOT_QUEUE
		@_fetchBuilds @buildModels.length, @buildModels.length + @_numberOfBuildsToRequest, queuePolicy


	_fetchBuilds: (start, end, queuePolicy) =>
		assert.ok start < end and queuePolicy? and not @noMoreBuildsToFetch
		return if not @get('repositoryId')?

		buildsQuery = new BuildsQuery @get('repositoryId'), @get('listType'), @get('queryString'), start, end
		@buildsFetcher.runQuery buildsQuery, queuePolicy, (error, result) =>
			if error? 
				console.error 'Error when retrieving builds ' + error
				return

			# It's possible this is being called for an old query
			return if result.listType isnt @get 'listType'
			return if result.queryString isnt @get 'queryString'

			# If we didn't receive as many builds as we were 
			#   expecting, we must have reached the end.
			@noMoreBuildsToFetch = (end - start > result.builds.length)

			@buildModels.add result.builds


class BuildsList.View extends Backbone.View
	tagName: 'div'
	className: 'buildsList'
	template: Handlebars.compile ''
	events:
		'scroll': '_scrollHandler'

	initialize: () =>
		@model.buildModels.on 'add', (buildModel, collection, options) =>
			buildView = new Build.View model: buildModel
			@_insertBuildAtIndex buildView.render().el, options.index
		@model.buildModels.on 'reset', () =>
			@$el.empty()


	render: () =>
		@$el.html @template()
		@model.buildModels.each (buildModel) =>
			buildView = new Build.View model: buildModel
			@$el.append buildView.render().el
		return @


	_scrollHandler: () =>
		heightBeforeFetchingMoreBuilds = 100
		if @el.scrollTop + @el.clientHeight + heightBeforeFetchingMoreBuilds > @el.scrollHeight
			@model.fetchMoreBuildsDoNotQueue()


	_insertBuildAtIndex: (buildView, index) =>
		if index == 0 then $('.buildsList').prepend buildView
		else $('.buildsList .build:nth-child(' + index + ')').after buildView

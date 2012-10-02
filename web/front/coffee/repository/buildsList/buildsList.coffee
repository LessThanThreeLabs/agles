window.BuildsList = {}


class BuildsList.Model extends Backbone.Model

	initialize: () ->
		@buildModels = new Backbone.Collection
		@buildModels.model = Build.Model
		@buildModels.comparator = (buildModel) ->
			return -1.0 * buildModel.get 'number'

		@buildModels.on 'add', (buildModel, collection, options) =>
			@trigger 'add', buildModel, collection, options


	@noMoreBuildsToFetch = false
	fetchBuilds: (start, end, callback) ->
		assert.ok end > start

		@get('buildsFetcher').fetchBuilds @get('repositoryId'), @get('type'), start, end, (error, buildsData) =>
			if error? then console.error 'Error when retrieving builds ' + error
			else @buildModels.add buildsData

			# If we didn't receive as many builds as we were 
			#   expecting, we must have reached the end.
			@noMoreBuildsToFetch = (end - start > buildsData.length)

			callback() if callback?


	fetchMoreBuilds: (number, callback) ->
		@fetchBuilds @buildModels.length, @buildModels.length + number, callback



class BuildsList.View extends Backbone.View
	tagName: 'div'
	className: 'buildsList'
	template: Handlebars.compile ''
	events:
		'scroll': 'scrollHandler'

	initialize: () ->
		@model.on 'add', @handleAdd
		$(window).bind 'resize', @resizeHandler


	render: () ->
		@$el.html @template()
		@model.buildModels.each (buildModel) =>
			buildView = new Build.View model: buildModel
			$('.buildsList').append buildView.render().el
		return @


	loadInitialBuilds: (initialAmount, deltaAmount) ->
		assert.ok initialAmount? and deltaAmount?
		@model.fetchMoreBuilds initialAmount, () =>
			@_loadBuildsToFitHeight deltaAmount


	_loadBuildsToFitHeight: (deltaAmount) =>
		if not @model.noMoreBuildsToFetch and (@el.scrollHeight < @el.clientHeight * 2)
			@model.fetchMoreBuilds deltaAmount, () =>
				@_loadBuildsToFitHeight deltaAmount


	handleAdd: (buildModel, collection, options) =>
		buildView = new Build.View model: buildModel
		@_insertBuildAtIndex buildView.render().el, options.index


	_insertBuildAtIndex: (buildView, index) =>
		if index == 0 then $('.buildsList').prepend buildView
		else $('.buildsList .build:nth-child(' + index + ')').after buildView


	scrollHandler: () =>
		heightBeforeFetchingMoreBuilds = 100
		if @el.scrollTop + @el.clientHeight + heightBeforeFetchingMoreBuilds > @el.scrollHeight
			@model.fetchMoreBuilds 20


	resizeHandler: () =>
		@_loadBuildsToFitHeight()

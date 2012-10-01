window.BuildsList = {}


class BuildsList.Model extends Backbone.Model

	initialize: () ->
		@buildModels = new Backbone.Collection
		@buildModels.model = Build.Model
		@buildModels.comparator = (buildModel) ->
			return -1.0 * buildModel.get 'number'

		@buildModels.on 'add', (buildModel, collection, options) =>
			@trigger 'add', buildModel, collection, options


	@fetchingBuilds = false
	fetchBuilds: (start, end) =>
		return false if @fetchingBuilds
		@fetchingBuilds = true

		requestData = 
			repositoryId: @get 'repositoryId'
			range: 
				start: start
				end: end

		socket.emit 'builds:read', requestData, (error, buildsData) =>
			if error? then console.error 'Error when retrieving builds' 
			else @buildModels.add buildsData 
			@fetchingBuilds = false


	fetchMoreBuilds: (number) ->
		@fetchBuilds @buildModels.length, @buildModels.length + number


class BuildsList.View extends Backbone.View
	tagName: 'div'
	className: 'buildsList'
	template: Handlebars.compile ''
	events:
		'scroll': 'checkScroll'

	initialize: () ->
		@model.on 'add', @handleAdd


	render: () ->
		@$el.html @template()
		@model.buildModels.each (buildModel) =>
			buildView = new Build.View model: buildModel
			$('.buildsList').append buildView.render().el
		return @


	handleAdd: (buildModel, collection, options) =>
		buildView = new Build.View model: buildModel
		@_insertBuildAtIndex buildView.render().el, options.index


	_insertBuildAtIndex: (buildView, index) =>
		if index == 0 then $('.buildsList').prepend buildView
		else $('.buildsList .build:nth-child(' + index + ')').after buildView


	checkScroll: () =>
		heightBeforeFetchingMoreBuilds = 100
		if @el.scrollTop + @el.clientHeight + heightBeforeFetchingMoreBuilds > @el.scrollHeight
			@model.fetchMoreBuilds 20

window.Repository = {}


class Repository.Model extends Backbone.Model
	urlRoot: 'repositories'

	initialize: () ->
		@buildModels = new Backbone.Collection
		@buildModels.model = Build.Model
		@buildModels.comparator = (buildModel) ->
			return -1.0 * buildModel.get 'number'

		@buildModels.on 'add', (buildModel, collection, options) =>
			@trigger 'add', buildModel, collection, options


	fetchBuilds: (start, end) ->
		requestData = 
			repositoryId: @id
			range: 
				start: start
				end: end

		socket.emit 'builds:read', requestData, (error, buildsData) =>
			@buildModels.add buildsData


class Repository.View extends Backbone.View
	tagName: 'div'
	className: 'repository'
	template: Handlebars.compile '<div class="buildsList"></div>'

	initialize: () ->
		@buildViews = []
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


repositoryModel = new Repository.Model id: Math.floor Math.random() * 10000
repositoryModel.fetch()
repositoryModel.fetchBuilds 0, 3

repositoryView = new Repository.View model: repositoryModel
$('#mainContainer').append repositoryView.render().el

setInterval (() -> repositoryModel.fetchBuilds 0, 3), 10000

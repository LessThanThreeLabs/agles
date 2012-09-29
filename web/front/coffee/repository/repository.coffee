window.Repository = {}


class Repository.Model extends Backbone.Model
	urlRoot: 'repositories'

	initialize: () ->
		@buildModels = new Backbone.Collection model:Build.Model
		@buildModels.on 'add', (buildModel) =>
			@trigger 'add', buildModel


	fetchBuilds: (start, end) ->
		requestData = 
			repositoryId: @id
			range: 
				start: start
				end: end

		socket.emit 'builds:read', requestData, (error, buildsData) =>
			console.log 'buildsData: ' + JSON.stringify buildsData
			@buildModels.add buildsData


class Repository.View extends Backbone.View
	tagName: 'div'
	className: 'repository'
	template: Handlebars.compile '<div class="buildsList"></div>'

	initialize: () ->
		@model.on 'add', @handleAdd


	render: () ->
		@$el.html @template()
		@model.buildModels.each (buildModel) =>
			buildView = new Build.View model: buildModel
			$('.buildsList').append buildView.render().el
		return @


	handleAdd: (buildModel) =>
		buildView = new Build.View model: buildModel
		$('.buildsList').append buildView.render().el


repositoryModel = new Repository.Model id: Math.floor Math.random() * 10000
repositoryModel.fetch
	error: (model, response) ->
 		console.log 'failed to get repository info: ' + response
repositoryModel.fetchBuilds 0, 20

repositoryView = new Repository.View model: repositoryModel
$('#mainContainer').append repositoryView.render().el








# loadRepository = (repositoryId) ->
# 	requestData = 
# 		repositoryId: repositoryId,
# 		range:
# 			start: 0
# 			end: 20
			
# 	await
# 		socket.emit 'repositories:read', repositoryId: repositoryId, defer repositoryData
# 		socket.emit 'builds:read', requestData, defer buildsData

# 	repositoryModel = new Repository.Model()
# 	repositoryView = new Repository.View model: repositoryModel
# 	$('body').append repositoryView.render().el



	# TODO: this is for testing... get rid of this soon...
	# addNewBuild: () ->
	# 	buildModel = new Build.Model()
	# 	buildModel.set
	# 		id: Math.floor Math.random() * 10000
	# 		repositoryId: Math.floor Math.random() * 1000
	# 	@buildModels.add buildModel

	# 	buildModel.fetch
	# 		success: (model, response) ->
	# 			console.log 'fetched successfully! ' + response
	# 			console.log 'model:'
	# 			for key, value of model.attributes
	# 				console.log '  ' + key + ': ' + value
	# 		error: (model, response) ->
	# 			console.log 'failed to fetch: ' + response
window.Repository = {}


class Repository.Model extends Backbone.Model

	initialize: () ->
		@buildModels = new Backbone.Collection model:Build.Model
		@buildModels.on 'add', (buildModel) =>
			@trigger 'add', buildModel
			

	# TODO: this is for testing... get rid of this soon...
	addNewBuild: () ->
		buildModel = new Build.Model()
		buildModel.set
			id: Math.floor Math.random() * 10000
			repositoryId: Math.floor Math.random() * 1000
		@buildModels.add buildModel

		buildModel.fetch
			success: (model, response) ->
				console.log 'fetched successfully! ' + response
				console.log 'model:'
				for key, value of model.attributes
					console.log '  ' + key + ': ' + value
			error: (model, response) ->
				console.log 'failed to fetch: ' + response


class Repository.View extends Backbone.View
	tagName: 'div'
	id: 'repository'
	events: 'click': 'clickHandler'

	initialize: () ->
		@model.on 'add', @handleAdd


	render: () ->
		@$el.html 'Hello'
		return @


	handleAdd: (buildModel) =>
		buildView = new Build.View model: buildModel
		@$el.append buildView.render().el


	clickHandler: () ->
		@model.addNewBuild()


repositoryModel = new Repository.Model()
repositoryView = new Repository.View model: repositoryModel

$('body').append repositoryView.render().el

window.BuildOutput = {}


class BuildOutput.Model extends Backbone.Model
	urlRoot: 'buildOutputs'
	defaults:
		buildId: null

	initialize: () =>
		@buildOutputLineModels = new Backbone.Collection()
		@buildOutputLineModels.model = BuildOutputLine.Model
		@buildOutputLineModels.comparator = (buildOutputLineModel) =>
			return buildOutputLineModel.get 'number'


	fetchBuildOutput: () =>
		console.log '>> needs to fetch output text'
		@buildOutputLineModels.reset @_createFakeOutputLines()


# NOT REAL ==>
	_createFakeOutputLines: () =>
		return (@_createFakeLine num for num in [0...900])


	_createFakeLine: (number) =>
		return toReturn = 
			number: number
			text: @_createRandomText()


	_createRandomText: () =>
		toReturn = ''
		characters = 'abcdefghijklmnopqrstuvwxyz '

		for num in [0...80]
			toReturn += characters.charAt Math.floor(Math.random() * characters.length)

		return toReturn
# <== NOT REAL


class BuildOutput.View extends Backbone.View
	tagName: 'div'
	className: 'buildOutput'
	template: Handlebars.compile '<div class="buildOutputText"></div>'

	initialize: () =>
		@model.buildOutputLineModels.on 'addLine', @_handleAddLine
		@model.buildOutputLineModels.on 'reset', @_initializeOutputText


	render: () =>
		@$el.html @template()
		@_initializeOutputText()
		return @


	_initializeOutputText: () =>
		$('.buildOutputText').empty()

		@model.buildOutputLineModels.each (buildOutputLineModel) =>
			buildOutputLineView = new BuildOutputLine.View model: buildOutputLineModel
			@$el.find('.buildOutputText').append buildOutputLineView.render().el


	_handleAddLine: (buildOutputLineModel) =>
		console.log 'need to do something here...'
		# buildOutputLineView = new BuildOutputLine.View model: buildOutputLineModel
		# @_insertBuildOutputLineAtIndex buildOutputLineView.render().el, buildOutputLineModel.get 'number'


	# _insertBuildOutputLineAtIndex: (buildOutputLineView, index) =>
	# 	if index == 0 then $('.buildOutputText').prepend buildOutputLineView
	# 	else $('.buildOutputText .buildOutputLine:nth-child(' + index + ')').after buildOutputLineView

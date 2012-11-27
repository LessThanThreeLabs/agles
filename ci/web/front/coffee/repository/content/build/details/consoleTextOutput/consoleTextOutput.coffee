window.ConsoleTextOutput = {}


class ConsoleTextdOutput.Model extends Backbone.Model
	defaults:
		id: null
		title: null

	initialize: () =>
		@consoleTextOutputLineModels = new Backbone.Collection()
		@consoleTextOutputLineModels.model = ConsoleTextOutputLine.Model
		@consoleTextOutputLineModels.comparator = (consoleTextOutputLine) =>
			return consoleTextOutputLine.get 'number'


	fetchBuildOutput: () =>
		console.log '>> needs to fetch output text'
		@consoleTextOutputLineModels.reset @_createFakeOutputLines()


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


class ConsoleTextdOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleTextOutput'
	template: Handlebars.compile '<div class="title">{{title}}</div><div class="output"></div>'

	initialize: () =>
		@model.on 'change:title', @render
		@model.consoleTextOutputLineModels.on 'addLine', @_handleAddLine
		@model.consoleTextOutputLineModels.on 'reset', @_initializeOutputText


	render: () =>
		@$el.html @template
			title: @model.get 'title'
		@_initializeOutputText()
		return @


	_initializeOutputText: () =>
		$('.output').empty()

		@model.consoleTextOutputLineModels.each (consoleTextOutputLineModel) =>
			consoleTextOutputLineView = new ConsoleTextOutputLine.View model: consoleTextOutputLineModel
			@$el.find('.output').append consoleTextOutputLineView.render().el


	_handleAddLine: (buildOutputLineModel) =>
		console.log 'need to do something here...'
		# buildOutputLineView = new BuildOutputLine.View model: buildOutputLineModel
		# @_insertBuildOutputLineAtIndex buildOutputLineView.render().el, buildOutputLineModel.get 'number'


	# _insertBuildOutputLineAtIndex: (buildOutputLineView, index) =>
	# 	if index == 0 then $('.buildOutputText').prepend buildOutputLineView
	# 	else $('.buildOutputText .buildOutputLine:nth-child(' + index + ')').after buildOutputLineView

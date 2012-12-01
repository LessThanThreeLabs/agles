window.ConsoleTextOutput = {}


class ConsoleTextOutput.Model extends Backbone.Model
	defaults:
		id: null
		title: null


	initialize: () =>
		@consoleTextOutputLineModels = new Backbone.Collection()
		@consoleTextOutputLineModels.model = ConsoleTextOutputLine.Model
		@consoleTextOutputLineModels.comparator = (consoleTextOutputLine) =>
			return consoleTextOutputLine.get 'number'


	fetchOutput: () =>
		socket.emit 'buildOutputs:read', id: @get('id'), (error, result) =>
			if error?
				console.error error
				return

			@set 'title', result.title
			@_addLineModels result.consoleOutput


	_addLineModels: (consoleOutput) =>
		lineModels = []
		for number, text of consoleOutput
			assert.ok not isNaN parseInt number

			lineModel = new ConsoleTextOutputLine.Model
				number: parseInt number
				text: text
			lineModels.push lineModel

		@consoleTextOutputLineModels.reset lineModels


class ConsoleTextOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleTextOutput'
	html: '<div class="title"></div><div class="output"></div>'


	initialize: () =>
		@model.on 'change:title', @_updateTitle, @
		@model.consoleTextOutputLineModels.on 'addLine', @_handleAddLine, @
		@model.consoleTextOutputLineModels.on 'reset', @_initializeOutputText, @


	onDispose: () =>
		@model.off null, null, @
		@model.consoleTextOutputLineModels.off null, null, @


	render: () =>
		@$el.html @html 
		@_updateTitle()
		@model.fetchOutput()
		return @


	_updateTitle: () =>
		@$el.find('.title').html @model.get 'title'


	_initializeOutputText: () =>
		@$el.find('.output').empty()

		# we want to load all of the DOM elements at once, for performance reasons
		htmlToAdd = $ '<div>'
		@model.consoleTextOutputLineModels.each (consoleTextOutputLineModel) =>
			consoleTextOutputLineView = new ConsoleTextOutputLine.View model: consoleTextOutputLineModel
			htmlToAdd.append consoleTextOutputLineView.render().el
		@$el.find('.output').html htmlToAdd.html()


	_handleAddLine: (buildOutputLineModel) =>
		console.log 'need to do something here...'
		# buildOutputLineView = new BuildOutputLine.View model: buildOutputLineModel
		# @_insertBuildOutputLineAtIndex buildOutputLineView.render().el, buildOutputLineModel.get 'number'


	# _insertBuildOutputLineAtIndex: (buildOutputLineView, index) =>
	# 	if index == 0 then $('.buildOutputText').prepend buildOutputLineView
	# 	else $('.buildOutputText .buildOutputLine:nth-child(' + index + ')').after buildOutputLineView

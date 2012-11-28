window.ConsoleTextOutput = {}


class ConsoleTextOutput.Model extends Backbone.Model
	urlRoot: 'buildOutputs'
	defaults:
		id: null
		title: null


	initialize: () =>
		@consoleTextOutputLineModels = new Backbone.Collection()
		@consoleTextOutputLineModels.model = ConsoleTextOutputLine.Model
		@consoleTextOutputLineModels.comparator = (consoleTextOutputLine) =>
			return consoleTextOutputLine.get 'number'


	fetchOutput: () =>
		console.log 'consoleTextOutput -- this should actually be a fetch'

		socket.emit 'buildOutputs:read', id: @get('id'), (error, result) =>
			if error?
				console.error error
				return

			@set 'title', result.subtype

			if result.console_output?
				@consoleTextOutputLineModels.reset @_generateLineModelsFromText result.console_output


		@_beginPolling()


	_beginPolling: () =>
		setInterval (() =>
			socket.emit 'buildOutputs:read', id: @get('id'), (error, result) =>
				if error?
					console.error error
					return

				return if not result.console_output?
				@consoleTextOutputLineModels.reset @_generateLineModelsFromText result.console_output
			), 3000


	_generateLineModelsFromText: (text) =>
		lines = text.split '\n'
		return (@_generateLineModel number, line for line, number in lines)


	_generateLineModel: (number, line) =>
		return toReturn =
			number: number
			text: line


class ConsoleTextOutput.View extends Backbone.View
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
		@model.fetchOutput()
		return @


	_initializeOutputText: () =>
		@$el.find('.output').empty()

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

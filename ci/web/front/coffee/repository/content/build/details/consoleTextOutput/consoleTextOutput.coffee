window.ConsoleTextOutput = {}


class ConsoleTextOutput.Model extends Backbone.Model
	urlRoot: 'buildOutputs'
	defaults:
		id: null
		title: null
		currentText: null


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

			@set 'currentText', result.console_output

			@set 'title', result.subtype
			@consoleTextOutputLineModels.reset @_generateLineModelsFromText result.console_output

			@beginPolling()


	_generateLineModelsFromText: (text) =>
		lines = text.split '\n'
		return (@_generateLineModel number, line for line, number in lines)


	_generateLineModel: (number, line) =>
		return toReturn =
			number: number
			text: line


	beginPolling: () =>
		setInterval (() =>
			socket.emit 'buildOutputs:read', id: @get('id'), (error, result) =>
				if error?
					console.error error
					return

				text = result.console_output
				text = text.substr @get('currentText').length + 1
				@set 'currentText', result.console_output

				lines = text.split '\n'

				startNumber = @consoleTextOutputLineModels.length
				@consoleTextOutputLineModels.add (@_generateLineModel (startNumber + number), line for line, number in lines)


			), 2000


class ConsoleTextOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleTextOutput'
	template: Handlebars.compile '<div class="title">{{title}}</div><div class="output"></div>'

	initialize: () =>
		@model.on 'change:title', @render
		@model.consoleTextOutputLineModels.on 'add', @_handleAddLine
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


	_handleAddLine: (consoleTextOutputLineModel, collection, options) =>
		consoleTextOutputLineView = new ConsoleTextOutputLine.View model: consoleTextOutputLineModel
		@$el.find('.output').append consoleTextOutputLineView.render().el

		# buildOutputLineView = new BuildOutputLine.View model: buildOutputLineModel
		# @_insertBuildOutputLineAtIndex buildOutputLineView.render().el, buildOutputLineModel.get 'number'


	# _insertBuildOutputLineAtIndex: (buildOutputLineView, index) =>
	# 	if index == 0 then $('.buildOutputText').prepend buildOutputLineView
	# 	else $('.buildOutputText .buildOutputLine:nth-child(' + index + ')').after buildOutputLineView

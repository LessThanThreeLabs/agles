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

			@set 'title', result.subtype
			if result.console_output?
				@consoleTextOutputLineModels.reset result.console_output


class ConsoleTextOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleTextOutput'
	template: Handlebars.compile '<div class="title">{{title}}</div><div class="output"></div>'


	initialize: () =>
		@model.on 'change:title', @_updateTitle, @
		@model.consoleTextOutputLineModels.on 'addLine', @_handleAddLine, @
		@model.consoleTextOutputLineModels.on 'reset', @_initializeOutputText, @


	onDispose: () =>
		@model.off null, null, @
		@model.consoleTextOutputLineModels.off null, null, @


	render: () =>
		@$el.html @template 
			title: @model.get 'title'
		@model.fetchOutput()
		return @


	_updateTitle: () =>
		@$el.html @template 
			title: @model.get 'title'
		@_initializeOutputText()


	_initializeOutputText: () =>
		@$el.find('.output').empty()

		console.log 'consoleTextOutput -- need to render the lines properly'
		# htmlToAdd = $ 'div'
		# @model.consoleTextOutputLineModels.each (consoleTextOutputLineModel) =>
		# 	consoleTextOutputLineView = new ConsoleTextOutputLine.View model: consoleTextOutputLineModel
		# 	htmlToAdd.append consoleTextOutputLineView.render().el

		# @$el.find('.output').html htmlToAdd.html()


	_handleAddLine: (buildOutputLineModel) =>
		console.log 'need to do something here...'
		# buildOutputLineView = new BuildOutputLine.View model: buildOutputLineModel
		# @_insertBuildOutputLineAtIndex buildOutputLineView.render().el, buildOutputLineModel.get 'number'


	# _insertBuildOutputLineAtIndex: (buildOutputLineView, index) =>
	# 	if index == 0 then $('.buildOutputText').prepend buildOutputLineView
	# 	else $('.buildOutputText .buildOutputLine:nth-child(' + index + ')').after buildOutputLineView

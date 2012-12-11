window.ConsoleTextOutput = {}


class ConsoleTextOutput.Model extends Backbone.Model
	subscribeUrl: 'buildOutputs'
	subscribeId: null
	defaults:
		id: null
		title: null
		expanded: false


	initialize: () =>
		@subscribeId = @get 'id'

		@consoleTextOutputLineModels = new Backbone.Collection()
		@consoleTextOutputLineModels.model = ConsoleTextOutputLine.Model
		@consoleTextOutputLineModels.comparator = (consoleTextOutputLine) =>
			return consoleTextOutputLine.get 'number'


	fetchOutput: () =>
		socket.emit 'buildOutputs:read', id: @get('id'), (error, result) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error error
			else
				@set 'title', result.title
				@_addLineModels result.consoleOutput


	onUpdate: (data) =>
		assert.ok data.type?

		if data.type is 'line added'
			assert.ok data.contents.number? and data.contents.text?
			lineModel = new ConsoleTextOutputLine.Model data.contents
			@consoleTextOutputLineModels.add lineModel
		else
			console.error 'Unaccounted for update type: ' + data.type


	_addLineModels: (consoleOutput) =>
		lineModels = []
		for number, text of consoleOutput
			assert.ok not isNaN parseInt number

			lineModel = new ConsoleTextOutputLine.Model
				number: parseInt number
				text: text
			lineModels.push lineModel

		@consoleTextOutputLineModels.reset lineModels


	toggleExpanded: () =>
		@set 'expanded', not @get 'expanded'


class ConsoleTextOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleTextOutput'
	html: '<div class="title"></div>
		<div class="outputSlidingWindow">
			<div class="output"></div>
		</div>'
	events: 'click': '_handleClick'


	initialize: () =>
		@model.on 'change:title', @_updateTitle, @
		@model.on 'change:expanded', @_updateExpandedState, @
		@model.consoleTextOutputLineModels.on 'add', @_handleAddLine, @
		@model.consoleTextOutputLineModels.on 'reset', @_initializeOutputText, @
		
		@model.subscribe()


	onDispose: () =>
		@model.off null, null, @
		@model.unsubscribe()
		@model.consoleTextOutputLineModels.off null, null, @


	render: () =>
		@$el.html @html 
		@_updateTitle()
		@model.fetchOutput()
		return @


	_handleClick: (event) =>
		@model.toggleExpanded()


	_updateTitle: () =>
		@$el.find('.title').html @model.get 'title'


	_updateExpandedState: () =>
		if @model.get 'expanded'
			@$('.outputSlidingWindow').height ($(window).height() * .67)
		else
			@$('.outputSlidingWindow').height 0



	_initializeOutputText: () =>
		@$el.find('.output').empty()

		# we want to load all of the DOM elements at once, for performance reasons
		htmlToAdd = $ '<div>'
		@model.consoleTextOutputLineModels.each (consoleTextOutputLineModel) =>
			consoleTextOutputLineView = new ConsoleTextOutputLine.View model: consoleTextOutputLineModel
			htmlToAdd.append consoleTextOutputLineView.render().el
		@$el.find('.output').html htmlToAdd.html()


	_handleAddLine: (consoleTextOutputLineModel, collection, options) =>
		consoleTextOutputLineView = new ConsoleTextOutputLine.View model: consoleTextOutputLineModel
		@_insertBuildOutputLineAtIndex consoleTextOutputLineView.render().el, options.index


	_insertBuildOutputLineAtIndex: (consoleTextOutputLineView, index) =>
		if index == 0 
			@$el.find('.output').prepend consoleTextOutputLineView
		else 
			@$el.find('.output .consoleTextOutputLine:nth-child(' + index + ')').after consoleTextOutputLineView

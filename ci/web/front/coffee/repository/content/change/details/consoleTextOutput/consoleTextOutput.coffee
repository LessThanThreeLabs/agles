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
	html: '<div class="titleContainer">
			<div class="title"></div>
			<div class="expandCollapse"></div>
		</div>
		<div class="outputSlidingWindow">
			<div class="output"></div>
		</div>'
	events: 'click .titleContainer': '_handleTitleClick'


	initialize: () =>
		@model.on 'change:title', @_updateTitle, @
		@model.on 'change:expanded', @_updateExpandedState, @
		@model.consoleTextOutputLineModels.on 'add', @_handleAddLine, @
		@model.consoleTextOutputLineModels.on 'reset', @_initializeOutputText, @
		
		@model.subscribe()
		@model.fetchOutput()


	onDispose: () =>
		@model.off null, null, @
		@model.unsubscribe()
		@model.consoleTextOutputLineModels.off null, null, @


	render: () =>
		@$el.html @html 
		@_updateTitle()
		@_updateExpandedState()
		return @


	_handleTitleClick: (event) =>
		@model.toggleExpanded()


	_updateTitle: () =>
		@$('.title').html @model.get 'title'


	_updateExpandedState: () =>
		if @model.get 'expanded'
			@$('.titleContainer').addClass 'expanded'
			@$('.outputSlidingWindow').height ($(window).height() * .67)
		else
			@$('.titleContainer').removeClass 'expanded'
			@$('.outputSlidingWindow').height 0

		@_updateExpandCollapseText()


	_updateExpandCollapseText: () =>
		if @model.get 'expanded'
			@$('.expandCollapse').html 'click to collapse'
		else
			@$('.expandCollapse').html 'click to expand'


	_initializeOutputText: () =>
		@$el.find('.output').empty()

		# we want to load all of the DOM elements at once, for performance reasons
		htmlToAdd = $ '<div>'
		@model.consoleTextOutputLineModels.each (consoleTextOutputLineModel) =>
			consoleTextOutputLineView = new ConsoleTextOutputLine.View model: consoleTextOutputLineModel
			htmlToAdd.append consoleTextOutputLineView.render().el
		@$('.output').html htmlToAdd.html()


	_handleAddLine: (consoleTextOutputLineModel, collection, options) =>
		consoleTextOutputLineView = new ConsoleTextOutputLine.View model: consoleTextOutputLineModel
		@_insertBuildOutputLineAtIndex consoleTextOutputLineView.render().el, options.index


	_insertBuildOutputLineAtIndex: (consoleTextOutputLineView, index) =>
		if index == 0 
			@$('.output').prepend consoleTextOutputLineView
		else 
			@$('.output .consoleTextOutputLine:nth-child(' + index + ')').after consoleTextOutputLineView

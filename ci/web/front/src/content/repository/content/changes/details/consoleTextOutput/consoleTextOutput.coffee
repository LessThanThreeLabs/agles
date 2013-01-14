window.ConsoleTextOutput = {}


class ConsoleTextOutput.Model extends Backbone.Model
	subscribeUrl: 'buildOutputs'
	subscribeId: null
	defaults:
		lines: []

	initialize: () =>
		@subscribeId = @get 'id'


	fetchOutput: () =>
		socket.emit 'buildOutputs:read', id: @get('id'), (error, result) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error error
			else
				@_addInitialLines result.consoleOutput


	_addInitialLines: (consoleOutput) =>
		linesToAdd = []
		for number, text of consoleOutput
			assert.ok number > 0   # lines[0] will be undefined
			linesToAdd[number] = text

		@set 'lines', linesToAdd,
			error: (model, error) => console.error error


	onUpdate: (data) =>
		return if  data.type isnt 'new output'

		# TODO: THIS NEEDS TO BE FIXED TO USE AN ARRAY!!
		# for lineNumber, lineText of data.contents.new_lines
		lineNumber = data.contents.line_num
		lineText = data.contents.line

		assert.ok lineNumber > 0

		if @get('lines')[lineNumber]?
			@get('lines')[lineNumber] = lineText
			@trigger 'lineUpdated', lineNumber, lineText
		else
			@get('lines')[lineNumber] = lineText
			@trigger 'lineAdded', lineNumber, lineText


class ConsoleTextOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleTextOutput'
	html: '<div class="consoleTextOutputContent"></div>'


	initialize: () =>
		@model.on 'change:lines', @_addInitialLines, @
		@model.on 'lineUpdated', @_handleLineUpdated, @
		@model.on 'lineAdded', @_handleAddLine, @

		@model.subscribe()
		@model.fetchOutput()


	onDispose: () =>
		@model.off null, null, @
		@model.unsubscribe()


	render: () =>
		@$el.html @html 
		@_addInitialLines()
		return @


	_addInitialLines: () =>
		@$('.consoleTextOutputContent').empty()

		htmlToAdd = []
		for text, number in @model.get 'lines'
			continue if number is 0
			htmlToAdd.push @_createLineHtml number, text

		@$('.consoleTextOutputContent').html htmlToAdd.join '\n'


	_createLineHtml: (number, text='') =>
		return "<div class='consoleTextOutputLine' lineNumber='#{number}'>
				<span class='consoleTextOutputLineNumber'>#{number}</span>
				<span class='consoleTextOutputLineText'>#{text}</span>
			</div>"


	_handleLineUpdated: (number, text) =>
		oldLine = $(".consoleTextOutputContent .consoleTextOutputLine[lineNumber=#{number}]")
		oldLine.find('.consoleTextOutputLineText').html text


	_handleAddLine: (number, text) =>
		scrolledToBottom = @_isScrolledToBottom()

		@_addMissingLines number

		lineHtml = @_createLineHtml number, text
		@_addLineInCorrectPosition lineHtml, number

		@_scrollToBottom() if scrolledToBottom


	_addMissingLines: (number) =>
		numberLines = $('.consoleTextOutputContent .consoleTextOutputLine').length

		for index in [(numberLines+1)...number]
			lineHtml = @_createLineHtml index, ''
			@_addLineInCorrectPosition lineHtml, index


	_addLineInCorrectPosition: (lineHtml, lineNumber) =>
		if lineNumber is 1
			@$('.consoleTextOutputContent').prepend lineHtml
		else 
			@$('.consoleTextOutputContent .consoleTextOutputLine:nth-child(' + (lineNumber-1) + ')').after lineHtml


	_isScrolledToBottom: () =>
		return @$('.consoleTextOutputContent').outerHeight() -
			Math.abs(@$('.consoleTextOutputContent').offset().top) -
			@$el.height() - @$el.offset().top <= 0


	_scrollToBottom: () =>
		animationProperties = scrollTop: @$('.consoleTextOutputContent').outerHeight()
		animationOptions =
			duration: 1000
			queue: false
		@$el.animate animationProperties, animationOptions

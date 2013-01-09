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
				@_addLines result.consoleOutput


	_addLines: (consoleOutput) =>
		linesToAdd = []
		for number, text of consoleOutput
			assert.ok not isNaN parseInt number

			lineToAdd =
				number: parseInt number
				text: text
			linesToAdd.push lineToAdd

		console.log 'need to sort these lines!!'

		@set 'lines', linesToAdd,
			error: (model, error) => console.error error


	onUpdate: (data) =>
		if data.type is 'line added'
			assert.ok data.contents.number? and data.contents.text?
			lineToAdd =
				number: data.contents.number
				text: data.contents.text
			@get('lines').push lineToAdd
			@trigger 'lineAdded', lineToAdd
		else
			console.error 'Unaccounted for update type: ' + data.type


class ConsoleTextOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleTextOutput'
	html: '<div class="consoleTextOutputContent"></div>'


	initialize: () =>
		@model.on 'change:lines', @_addInitialLines, @
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
		for line in @model.get 'lines'
			htmlToAdd.push @_createLineHtml line

		@$('.consoleTextOutputContent').html htmlToAdd.join '\n'


	_createLineHtml: (line) =>
		return "<div class='consoleTextOutputLine' lineNumber='#{line.number}'>
				<span class='consoleTextOutputLineNumber'>#{line.number}</span>
				<span class='consoleTextOutputLineText'>#{line.text}</span>
			</div>"


	_handleAddLine: (line) =>
		lineHtml = @_createLineHtml line

		if line.number == 0 
			@$('.consoleTextOutputContent').prepend lineHtml
		else 
			@$('.consoleTextOutputContent .consoleTextOutputLine:nth-child(' + line.number + ')').after lineHtml

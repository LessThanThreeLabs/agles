window.ConsoleCompilationOutput = {}


class ConsoleCompilationOutput.Model extends Backbone.Model

	initialize: () =>
		@consoleTextOutputModels = (@_createFakeOutputModel num for num in [0...3])


	_createFakeOutputModel: (number) =>
		return new ConsoleTextOutput.Model
			id: number
			title: 'hello ' + number


class ConsoleCompilationOutput.View extends Backbone.View
	tagName: 'div'
	className: 'consoleCompilationOutput'
	template: Handlebars.compile ''


	render: () =>
		@$el.html @template()

		for consoleTextOutputModel in @model.consoleTextOutputModels
			consoleTextOutputView = new ConsoleTextOutput.View model: consoleTextOutputModel
			@$el.append consoleTextOutputView.render().el

		return @

window.ChangeDetails = {}


class ChangeDetails.Model extends Backbone.Model

	initialize: () =>
		@consoleCompilationOutputModel = new ConsoleCompilationOutput.Model()


class ChangeDetails.View extends Backbone.View
	tagName: 'div'
	className: 'changeDetails'
	html: '<div class="changeDetailsContentContainer">
				<div class="changeDetailsContent"></div>
			</div>'
	currentView: null


	initialize: () =>
		@compilationView = new ConsoleCompilationOutput.View model: @model.consoleCompilationOutputModel


	onDispose: () =>
		@compilationView.dispose()


	render: () =>
		@$el.html @html
		@$('.changeDetailsContent').html @compilationView.render().el
		return @

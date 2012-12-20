window.ChangeDetails = {}


class ChangeDetails.Model extends Backbone.Model

	initialize: () =>
		@consoleCompilationOutputModel = new ConsoleCompilationOutput.Model()


class ChangeDetails.View extends Backbone.View
	tagName: 'div'
	className: 'changeDetails'
	html: '<div class="changeDetailsContentContainer">
				<div class="changeDetailsContent">&nbsp</div>
			</div>'
	currentView: null


	initialize: () =>
		globalRouterModel.on 'change:changeView', @_updateContent, @


	onDispose: () =>
		globalRouterModel.off null, null, @
		@currentView.dispose() if @currentView?


	render: () =>
		@$el.html @html
		@_updateContent()
		return @
		

	_updateContent: () =>
		@currentView.dispose() if @currentView?

		switch globalRouterModel.get 'changeView'
			when 'information'
				@$el.find('.changeDetailsContent').empty()
				console.log 'changeDetails -- information view not implemented yet'
			when 'compilation'
				@currentView = new ConsoleCompilationOutput.View model: @model.consoleCompilationOutputModel
				@$el.find('.changeDetailsContent').html @currentView.render().el
			when 'test'
				@$el.find('.changeDetailsContent').empty()
				console.log 'changeDetails -- test view not implemented yet'
			when null
				@$el.find('.changeDetailsContent').empty()
				console.log 'changeDetails -- default view not implemented yet'
			else
				@$el.find('.changeDetailsContent').empty()
				console.error 'Unaccounted for view ' + globalRouterModel.get 'changeView'
	
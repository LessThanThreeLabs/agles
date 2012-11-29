window.BuildDetails = {}


class BuildDetails.Model extends Backbone.Model

	initialize: () =>
		@consoleCompilationOutputModel = new ConsoleCompilationOutput.Model()


class BuildDetails.View extends Backbone.View
	tagName: 'div'
	className: 'buildDetails'
	html: '<div class="buildDetailsContentContainer">
				<div class="buildDetailsContent">&nbsp</div>
			</div>'
	currentView: null


	initialize: () =>
		window.globalRouterModel.on 'change:buildView', @_updateContent


	onDispose: () =>
		window.globalRouterModel.off null, null, @
		@currentView.dispose() if @currentView?


	render: () =>
		@$el.html @html
		@_updateContent()
		return @
		

	_updateContent: () =>
		@currentView.dispose() if @currentView?

		switch window.globalRouterModel.get 'buildView'
			when 'information'
				@$el.find('.buildDetailsContent').empty()
				console.log 'buildDetails -- information view not implemented yet'
			when 'compilation'
				@currentView = new ConsoleCompilationOutput.View model: @model.consoleCompilationOutputModel
				@$el.find('.buildDetailsContent').html @currentView.render().el
			when 'test'
				@$el.find('.buildDetailsContent').empty()
				console.log 'buildDetails -- test view not implemented yet'
			when null
				@$el.find('.buildDetailsContent').empty()
				console.log 'buildDetails -- default view not implemented yet'
			else
				@$el.find('.buildDetailsContent').empty()
				console.error 'Unaccounted for view ' + window.globalRouterModel.get 'buildView'
	
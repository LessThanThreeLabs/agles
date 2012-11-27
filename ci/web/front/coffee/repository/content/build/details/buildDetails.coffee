window.BuildDetails = {}


class BuildDetails.Model extends Backbone.Model

	initialize: () =>
		


class BuildDetails.View extends Backbone.View
	tagName: 'div'
	className: 'buildDetails'


	initialize: () =>
		window.globalRouterModel.on 'change:buildView', @render


	render: () =>
		@$el.html '<div class="buildDetailsContent">&nbsp</div>'

		switch window.globalRouterModel.get 'buildView'
			when 'information'
				console.log 'buildDetails -- information view not implemented yet'
			when 'compilation'
				console.log 'buildDetails -- this model should be contained in its parent model'
				consoleCompilationOutputModel = new ConsoleCompilationOutput.Model()
				consoleCompilationOutputView = new ConsoleCompilationOutput.View model: consoleCompilationOutputModel
				@$el.find('.buildDetailsContent').html consoleCompilationOutputView.render().el
			when 'test'
				console.log 'buildDetails -- test view not implemented yet'
			when null
				console.log 'buildDetails -- default view not implemented yet'
				@$el.find('.buildDetailsContent').empty()
			else
				console.error 'Unaccounted for view ' + window.globalRouterModel.get 'buildView'

		return @
		
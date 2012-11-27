window.BuildDetails = {}


class BuildDetails.Model extends Backbone.Model

	initialize: () =>


class BuildDetails.View extends Backbone.View
	tagName: 'div'
	className: 'buildDetails'


	initialize: () =>
		window.globalRouterModel.on 'change:buildView', @render


	render: () =>
		@$el.html '&nbsp'

		switch window.globalRouterModel.get 'buildView'
			when 'information'
				console.log 'buildDetails -- information view not implemented yet'
			when 'compilation'
				console.log 'buildDetails -- compilation view not implemented yet'
			when 'test'
				console.log 'buildDetails -- test view not implemented yet'
			when null
				console.log 'buildDetails -- default view not implemented yet'
			else
				console.error 'Unaccounted for view ' + window.globalRouterModel.get 'buildView'

		return @
		
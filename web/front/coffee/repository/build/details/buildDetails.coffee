window.BuildDetails = {}


class BuildDetails.Model extends Backbone.Model
	
	initialize: () =>


	loadBuild: (buildId) =>



class BuildDetails.View extends Backbone.View
	tagName: 'div'
	className: 'buildDetails'
	template: Handlebars.compile ''

	initialize: () ->


	render: () ->
		@$el.html @template()
		return @

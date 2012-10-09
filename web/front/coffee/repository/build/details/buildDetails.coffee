window.BuildDetails = {}


class BuildDetails.Model extends Backbone.Model
	
	initialize: () =>


	loadBuild: (buildId) =>



class BuildDetails.View extends Backbone.View
	tagName: 'div'
	className: 'buildDetails'
	template: Handlebars.compile ''

	initialize: () =>


	render: () =>
		@$el.html @template()
		@_displayBuildOutput()
		return @


	_displayBuildOutput: () =>
		buildOutputModel = new BuildOutput.Model id: 17
		buildOutputModel.fetchBuildOutput()

		buildOutputView = new BuildOutput.View model: buildOutputModel
		@$el.append buildOutputView.render().el

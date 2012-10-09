window.BuildDetails = {}


class BuildDetails.Model extends Backbone.Model
	
	initialize: () =>


class BuildDetails.View extends Backbone.View
	tagName: 'div'
	className: 'buildDetails'
	template: Handlebars.compile ''

	initialize: () =>
		@model.on 'change:build', @_loadBuild

	render: () =>
		@$el.html @template()
		@_displayBuildOutput()
		return @


	_displayBuildOutput: () =>
		return if not @model.get('build')?

		buildOutputModel = new BuildOutput.Model id: @model.get('build').get('id')
		buildOutputModel.fetchBuildOutput()

		buildOutputView = new BuildOutput.View model: buildOutputModel
		@$el.append buildOutputView.render().el


	_loadBuild: (buildDetailsModel, build) =>
		@render()

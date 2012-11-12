window.BuildDetails = {}


class BuildDetails.Model extends Backbone.Model
	defaults:
		build: null

	initialize: () =>


class BuildDetails.View extends Backbone.View
	tagName: 'div'
	className: 'buildDetails'
	template: Handlebars.compile '<div class="buildDetailsContents">
			<div class="buildDetailsHeader">Console Output</div>
			<div class="buildDetailsPanel"></div>
		</div>'

	initialize: () =>
		@model.on 'change:build', @render


	render: () =>
		@$el.html @template()
		@_displayBuildOutput()
		return @


	_displayBuildOutput: () =>
		return if not @model.get('build')?

		# buildOutputModel = new BuildOutput.Model id: @model.get('build').get('id')
		# buildOutputModel.fetchBuildOutput()

		# buildOutputView = new BuildOutput.View model: buildOutputModel
		# @$el.find('.buildDetailsPanel').append buildOutputView.render().el

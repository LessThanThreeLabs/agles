window.BuildDetails = {}


class BuildDetails.Model extends Backbone.Model
	defaults:
		buildId: null

	initialize: () =>
		@on 'change: buildId', () =>
			console.log '~~ buildId changed to: ' + @get 'buildId'



class BuildDetails.View extends Backbone.View
	tagName: 'div'
	className: 'buildDetails'
	template: Handlebars.compile '<div class="buildDetailsContents">
			<div class="buildDetailsHeader">Console Output I HATE THIS HEADER</div>
			<div class="buildDetailsPanel"></div>
		</div>'

	initialize: () =>
		@model.on 'change:buildId', @render


	render: () =>
		@$el.html @template()
		@_displayBuildOutput()
		return @


	_displayBuildOutput: () =>
		console.log 'called'
		return if not @model.get('buildId')?

		console.log 'here'

		buildOutputModel = new BuildOutput.Model id: @model.get('buildId')
		buildOutputModel.fetchBuildOutput()

		buildOutputView = new BuildOutput.View model: buildOutputModel
		@$el.find('.buildDetailsPanel').html buildOutputView.render().el

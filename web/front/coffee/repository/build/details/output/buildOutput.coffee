window.BuildOutput = {}


class BuildOutput.Model extends Backbone.Model
	urlRoot: 'buildOutputs'

	initialize: () =>
		@buildOutputLineModels = new Backbone.Collection()
		@buildOutputLineModels.model = BuildOutputLine.Model
		@buildOutputLineModels.comparator = (buildOutputLineModel) =>
			return buildOutputLineModel.get 'number'

		@buildOutputLineModels.on 'add', (buildOutputLineModel, collection, options) =>
			@trigger 'addLine', buildOutputLineModel
		@buildOutputLineModels.on 'reset', (collection, options) =>
			@trigger 'addLines', collection


	fetchBuildOutput: () =>
		socket.emit 'buildOutputs:read', @get('id'), (error, buildOutputData) =>
			throw error if error?

			# Create and add all of the models at once for performance reasons.
			lineCounter = 0
			buildOutputLineModelAttributes = []
			for buildOutputLine in buildOutputData.text
				buildOutputLineModelAttributes.push
					number: lineCounter++
					text: @get('id') + ' ' + buildOutputLine

			@buildOutputLineModels.reset buildOutputLineModelAttributes


class BuildOutput.View extends Backbone.View
	tagName: 'div'
	className: 'buildOutput'
	template: Handlebars.compile '<div class="buildOutputHeader">Console Output:</div>
		<div class="buildOutputText"></div>'

	initialize: () =>
		@model.on 'addLine', @_handleAddLine
		@model.on 'addLines', @_addOutputLines


	render: () =>
		@$el.html @template()
		@_addOutputLines()
		return @


	_addOutputLines: () =>
		$('.buildOutputText').empty()
		@model.buildOutputLineModels.each (buildOutputLineModel) =>
			buildOutputLineView = new BuildOutputLine.View model: buildOutputLineModel
			$('.buildOutputText').append buildOutputLineView.render().el


	_handleAddLine: (buildOutputLineModel) =>
		buildOutputLineView = new BuildOutputLine.View model: buildOutputLineModel
		@_insertBuildOutputLineAtIndex buildOutputLineView.render().el, buildOutputLineModel.get 'number'


	_insertBuildOutputLineAtIndex: (buildOutputLineView, index) =>
		if index == 0 then $('.buildOutputText').prepend buildOutputLineView
		else $('.buildOutputText .buildOutputLine:nth-child(' + index + ')').after buildOutputLineView

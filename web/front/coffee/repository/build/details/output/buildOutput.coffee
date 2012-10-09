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


	fetchBuildOutput: () =>
		socket.emit 'buildOutputs:read', id: 17, (error, buildOutputData) =>
			throw error if error?

			lineCounter = 0
			for buildOutputLine in buildOutputData.text
				line = new BuildOutputLine.Model
					number: lineCounter
					text: buildOutputLine
				@buildOutputLineModels.add line
				++lineCounter


class BuildOutput.View extends Backbone.View
	tagName: 'div'
	className: 'buildOutput'
	template: Handlebars.compile '<div class="buildOutputHeader">Console Output:</div>
		<div class="buildOutputText"></div>'

	initialize: () =>
		@model.on 'addLine', @_handleAddLine


	render: () =>
		@$el.html @template()
		@model.buildOutputLineModels.each (buildOutputLineModel) =>
			buildOutputLineView = new BuildOutputLine.View model: buildOutputLineModel
			@$el.append buildOutputLineView.render().el
		return @


	_handleAddLine: (buildOutputLineModel) =>
		buildOutputLineView = new BuildOutputLine.View model: buildOutputLineModel
		@_insertBuildOutputLineAtIndex buildOutputLineView.render().el, buildOutputLineModel.get 'number'


	_insertBuildOutputLineAtIndex: (buildOutputLineView, index) =>
		if index == 0 then $('.buildOutputText').prepend buildOutputLineView
		else $('.buildOutputText .buildOutputLine:nth-child(' + index + ')').after buildOutputLineView

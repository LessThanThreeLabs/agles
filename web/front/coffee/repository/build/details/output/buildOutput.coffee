window.BuildOutput = {}


class BuildOutput.Model extends Backbone.Model
	urlRoot: 'buildOutputs'

	initialize: () ->


class BuildOutput.View extends Backbone.View
	tagName: 'div'
	className: 'buildOutput'
	template: Handlebars.compile '<div class="buildOutputHeader">Console Output:</div>
		<div class="buildOutputText"></div>'

	initialize: () ->
		@model.on 'change:text', (model, text) =>
			lineCounter = 0
			for line in text
				$('.buildOutputText').append @_createLine lineCounter, line
				++lineCounter


	render: () ->
		@$el.html @template()
		return @


	_createLine: (lineNumber, lineText) =>
		displayLineNumber = $ '<div/>',
			class: 'buildOutputLineNumber'
			text: lineNumber
		displayLineText = $ '<div/>',
			class: 'buildOutputLineText'
			text: lineText
		displayLine = $ '<div/>',
			class: 'buildOutputLine'

		return displayLine.append(displayLineNumber).append(displayLineText)
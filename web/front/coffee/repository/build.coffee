window.Build = {}


class Build.Model extends Backbone.Model
	urlRoot: 'builds'

	validate: (attributes) ->
		return


class Build.View extends Backbone.View
	tagName: 'div'
	className: 'build'
	template: Handlebars.compile '{{number}}'
	events: 'click': 'clickHandler'

	render: () ->
		@$el.html @template
			number: @model.get('number')
		return @


	clickHandler: () ->
		console.log 'clicked'








# addNewBuild = () ->
# 	buildModel = new Build.Model
# 		id: Math.floor Math.random() * 10000
# 		repositoryId: Math.floor Math.random() * 10000
# 		number: Math.floor Math.random() * 1000

# 	buildView = new Build.View model: buildModel
# 	$('body').append buildView.render().el

# addNewBuild()
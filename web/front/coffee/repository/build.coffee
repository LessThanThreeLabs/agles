window.Build = {}


class Build.Model extends Backbone.Model
	urlRoot: 'builds'

	# validate: (attributes) ->
	# 	if @number < 0 or not @owner? or @progress < 0 and @progress > 100 or not @success?
	# 		return new Error("Invalid Build.Model state")
	# 	else
	# 		return


class Build.View extends Backbone.View
	tagName: 'div'
	className: 'build'

	render: () ->
		@$el.html 'nerd up!'
		return @

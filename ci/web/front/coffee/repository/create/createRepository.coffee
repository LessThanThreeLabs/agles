window.CreateRepository = {}


class CreateRepository.Model extends Backbone.Model
	defaults:
		name: null
		description: null

	initialize: () =>


class CreateRepository.View extends Backbone.View
	tagName: 'div'
	className: 'createRepository'
	template: Handlebars.compile 'Hello'

	initialize: () =>

	render: () =>
		@$el.html @template()
		return @

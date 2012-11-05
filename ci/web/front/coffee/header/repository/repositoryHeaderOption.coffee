window.RepositoryHeaderOption = {}


class RepositoryHeaderOption.Model extends Backbone.Model
	defaults:
		visible: true

	initialize: () ->
		window.globalAccount.on 'change:firstName change:lastName', () =>
			console.log 'user logged in -- need to update repositories'


class RepositoryHeaderOption.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeaderOption headerMenuOption'
	template: Handlebars.compile 'Repositories'
	events: 'click': '_clickHandler'


	initialize: () ->
		@model.on 'change:visible', () =>
			@_fixVisibility()


	render: () ->
		@$el.html @template()
		return @


	_clickHandler: () =>
		console.log 'clicked'


	_fixVisibility: () =>
		@$el.toggle @model.get 'visible'

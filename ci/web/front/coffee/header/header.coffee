window.Header = {}


class Header.Model extends Backbone.Model

	initialize: () ->
		@headerMenuModel = new HeaderMenu.Model()


class Header.View extends Backbone.View
	tagName: 'div'
	className: 'header'
	template: Handlebars.compile '<div class="title">Blimp</div>'

	initialize: () ->
		@headerMenuView = new HeaderMenu.View model: @model.headerMenuModel

		@headerMenuView.on 'repositorySelected', (repositoryId) =>
			console.log 'repository selected ' + repositoryId


	render: () ->
		@$el.html @template()
		@$el.append @headerMenuView.render().el
		return @

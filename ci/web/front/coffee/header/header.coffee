window.Header = {}


class Header.Model extends Backbone.Model

	initialize: () ->
		@headerMenuModel = new HeaderMenu.Model()


class Header.View extends Backbone.View
	tagName: 'div'
	className: 'header'
	template: Handlebars.compile '<div class="headerContent"><span class="title">Blimp</span></div>'
	events: 'click .title': '_handleTitleClick'


	initialize: () ->
		@router = new Backbone.Router()
		@headerMenuView = new HeaderMenu.View model: @model.headerMenuModel


	render: () ->
		@$el.html @template()
		@$el.append @headerMenuView.render().el
		return @


	_handleTitleClick: () =>
		@router.navigate '/', trigger: true

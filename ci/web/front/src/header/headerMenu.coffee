window.HeaderMenu = {}


class HeaderMenu.Model extends Backbone.Model

	initialize: () =>
		@headerMenuAccountOptionModel = new HeaderMenuAccountOption.Model()
		@headerMenuLoginOptionModel = new HeaderMenuLoginOption.Model()
		@headerMenuRepositoryOptionModel = new HeaderMenuRepositoryOption.Model()


class HeaderMenu.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenu'
	html: ''


	initialize: () =>
		@headerMenuAccountOptionView = new HeaderMenuAccountOption.View model: @model.headerMenuAccountOptionModel
		@headerMenuLoginOptionView = new HeaderMenuLoginOption.View model: @model.headerMenuLoginOptionModel
		@headerMenuRepositoryOptionView = new HeaderMenuRepositoryOption.View model: @model.headerMenuRepositoryOptionModel


	onDispose: () =>
		@headerMenuAccountOptionView.dispose()
		@headerMenuLoginOptionView.dispose()
		@headerMenuRepositoryOptionView.dispose()
		

	render: () =>
		@$el.html @html

		@$el.append @headerMenuAccountOptionView.render().el
		@$el.append @headerMenuLoginOptionView.render().el
		@$el.append @headerMenuRepositoryOptionView.render().el
		
		return @

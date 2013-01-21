window.Main = {}


class Main.Model extends Backbone.Model

	initialize: () =>
		@headerModel = new Header.Model()
		@welcomeModel = new Welcome.Model()


class Main.View extends Backbone.View
	tagName: 'div'
	id: 'main'
	html: '<div class="headerContainer"></div><div class="contentContainer"></div>'


	initialize: () ->
		@headerView = new Header.View model: @model.headerModel
		@welcomeView = new Welcome.View model: @model.welcomeModel
		

	onDispose: () =>
		@headerView.dispose()
		@welcomeView.dispose()


	render: () ->
		@$el.html @html
		@$('.headerContainer').html @headerView.render().el
		@$('.contentContainer').html @welcomeView.render().el
		return @


mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el

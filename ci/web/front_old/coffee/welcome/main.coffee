window.Main = {}


class Main.Model extends Backbone.Model

	initialize: () =>
		@headerModel = new Header.Model()
		@welcomeModel = new Welcome.Model()


class Main.View extends Backbone.View
	tagName: 'div'
	id: 'main'
	html: '<div class="headerContainer"></div><div class="welcomeContainer"></div>'


	initialize: () ->
		@headerView = new Header.View model: @model.headerModel
		@welomeView = new Welcome.View model: @model.welcomeModel


	onDispose: () =>
		@headerView.dispose()
		@welcomeView.dispose()


	render: () ->
		@$el.html @html
		@$el.find('.headerContainer').html @headerView.render().el
		@$el.find('.contentContainer').html @welomeView.render().el
		return @


mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el

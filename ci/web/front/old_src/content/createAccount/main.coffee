window.Main = {}


class Main.Model extends Backbone.Model

	initialize: () =>
		@headerModel = new Header.Model()
		@createAccountModel = new CreateAccount.Model()


class Main.View extends Backbone.View
	tagName: 'div'
	id: 'main'
	html: '<div class="headerContainer"></div><div class="contentContainer"></div>'


	initialize: () ->
		@headerView = new Header.View model: @model.headerModel
		@createAccountView = new CreateAccount.View model: @model.createAccountModel
		

	onDispose: () =>
		@headerView.dispose()
		@createAccountView.dispose()


	render: () ->
		@$el.html @html
		@$('.headerContainer').html @headerView.render().el
		@$('.contentContainer').html @createAccountView.render().el
		return @


mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el

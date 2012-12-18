window.Main = {}


class Main.Model extends Backbone.Model

	initialize: () =>
		@headerModel = new Header.Model()
		@repositoryModel = new Repository.Model()


class Main.View extends Backbone.View
	tagName: 'div'
	id: 'main'
	html: '<div class="headerContainer"></div><div class="contentContainer"></div>'


	initialize: () ->
		@headerView = new Header.View model: @model.headerModel
		@repositoryView = new Repository.View model: @model.repositoryModel
		

	onDispose: () =>
		@headerView.dispose()
		@repositoryView.dispose()


	render: () ->
		@$el.html @html
		@$('.headerContainer').html @headerView.render().el
		@$('.contentContainer').html @repositoryView.render().el
		return @


mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el

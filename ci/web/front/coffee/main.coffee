window.Main = {}


class Main.Model extends Backbone.Model

	initialize: () ->
		@headerModel = new Header.Model()
		@repositoryModel = new Repository.Model id: Math.floor Math.random() * 10000
		@repositoryModel.fetch()


class Main.View extends Backbone.View
	tagName: 'div'
	id: 'main'
	template: Handlebars.compile '<div class="headerContainer"></div><div class="contentContainer"></div>'

	initialize: () ->
		@headerView = new Header.View model: @model.headerModel
		@repositoryView = new Repository.View model: @model.repositoryModel


	render: () ->
		@$el.html @template()
		@$el.find('.headerContainer').append @headerView.render().el
		@$el.find('.contentContainer').append @repositoryView.render().el
		return @


mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el

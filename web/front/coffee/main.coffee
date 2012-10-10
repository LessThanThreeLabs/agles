window.Main = {}


class Main.Model extends Backbone.Model

	initialize: () ->
		@repositoryModel = new Repository.Model id: Math.floor Math.random() * 10000
		@repositoryModel.fetch()


class Main.View extends Backbone.View
	tagName: 'div'
	id: 'main'
	template: Handlebars.compile ''

	initialize: () ->
		@repositoryView = new Repository.View model: @model.repositoryModel


	render: () ->
		@$el.html @template()
		@$el.append @repositoryView.render().el
		return @


mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').append mainView.render().el

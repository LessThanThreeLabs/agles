window.Repository = {}


class Repository.Model extends Backbone.Model
	urlRoot: 'repositories'

	initialize: () ->
		@buildsListManagerModel = new BuildsListManager.Model repositoryId: @id


class Repository.View extends Backbone.View
	tagName: 'div'
	className: 'repository'
	template: Handlebars.compile ''

	initialize: () ->
		@buildsListManagerView = new BuildsListManager.View model: @model.buildsListManagerModel


	render: () ->
		@$el.html @template()
		@$el.append @buildsListManagerView.render().el
		return @




repositoryModel = new Repository.Model id: Math.floor Math.random() * 10000
repositoryModel.fetch()

repositoryView = new Repository.View model: repositoryModel
$('#mainContainer').append repositoryView.render().el

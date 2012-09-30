window.Repository = {}


class Repository.Model extends Backbone.Model
	urlRoot: 'repositories'

	initialize: () ->
		@buildsListModel = new BuildsList.Model repositoryId: @id


	fetchBuilds: (start, end) ->
		@buildsListModel.fetchBuilds start, end


class Repository.View extends Backbone.View
	tagName: 'div'
	className: 'repository'
	template: Handlebars.compile ''

	initialize: () ->
		@buildsListView = new BuildsList.View model: @model.buildsListModel


	render: () ->
		@$el.html @template()
		@$el.append @buildsListView.render().el
		return @


repositoryModel = new Repository.Model id: Math.floor Math.random() * 10000
repositoryModel.fetch()
repositoryModel.fetchBuilds 0, 3

repositoryView = new Repository.View model: repositoryModel
$('#mainContainer').append repositoryView.render().el

setInterval (() -> repositoryModel.fetchBuilds 0, 3), 10000

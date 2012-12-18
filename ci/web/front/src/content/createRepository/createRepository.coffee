window.CreateRepository = {}


class CreateRepository.Model extends Backbone.Model

	initialize: () =>
		@createRepositoryFormModel = new CreateRepositoryForm.Model()


class CreateRepository.View extends Backbone.View
	tagName: 'div'
	className: 'createRepository'
	html: '<div class="createRepositoryFormContainer"></div>'


	initialize: () =>
		@createRepositoryFormView = new CreateRepositoryForm.View model: @model.createRepositoryFormModel


	onDispose: () =>
		@createRepositoryFormView.dispose()


	render: () =>
		@$el.html @html
		@$('.createRepositoryFormContainer').html @createRepositoryFormView.render().el
		return @

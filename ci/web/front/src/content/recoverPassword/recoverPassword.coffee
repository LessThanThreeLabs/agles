window.RecoverPassword = {}


class RecoverPassword.Model extends Backbone.Model

	initialize: () =>
		@recoverPasswordFormModel = new RecoverPasswordForm.Model()


class RecoverPassword.View extends Backbone.View
	tagName: 'div'
	className: 'recoverPassword'
	html: '<div class="recoverPasswordFormContainer"></div>'


	initialize: () =>
		@recoverPasswordFormView = new RecoverPasswordForm.View model: @model.recoverPasswordFormModel


	onDispose: () =>
		@recoverPasswordFormView.dispose()


	render: () =>
		@$el.html @html
		@$('.recoverPasswordFormContainer').html @recoverPasswordFormView.render().el
		return @

window.RecoverPassword = {}


class RecoverPassword.Model extends Backbone.Model

	initialize: () =>
		@recoverPasswordFormModel = new RecoverPasswordForm.Model()
		@recovePasswordSuccessModel = new RecoverPasswordSuccess.Model()

		@recoverPasswordFormModel.on 'change:email', () =>
			attributesToSet =
				email: @recoverPasswordFormModel.get 'email'
			@recovePasswordSuccessModel.set attributesToSet,
				error: (model, error) => console.error error


class RecoverPassword.View extends Backbone.View
	tagName: 'div'
	className: 'recoverPassword'
	html: '<div class="recoverPasswordFormContainer"></div>'


	initialize: () =>
		@recoverPasswordFormView = new RecoverPasswordForm.View model: @model.recoverPasswordFormModel
		@recovePasswordSuccessView = new RecoverPasswordSuccess.View model: @model.recovePasswordSuccessModel

		@recoverPasswordFormView.on 'passwordReset', @_showSuccess, @


	onDispose: () =>
		@recoverPasswordFormView.off null, null, @

		@recoverPasswordFormView.dispose()


	render: () =>
		@$el.html @html
		@$('.recoverPasswordFormContainer').html @recoverPasswordFormView.render().el
		return @


	_showSuccess: () =>
		@$el.html @recovePasswordSuccessView.render().el

window.RecoverPasswordForm = {}


class RecoverPasswordForm.Model extends Backbone.Model
	defaults:
		email: ''


	validate: (attributes) =>
		if typeof attributes.email isnt 'string'
			return new Error 'Invalid email: ' + attributes.email

		return


class RecoverPasswordForm.View extends Backbone.View
	tagName: 'div'
	className: 'recoverPasswordForm'
	html: '<div class="prettyForm">
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Email</div>
				<div class="prettyFormValue">
					<input type="email" class="recoverPasswordEmail" placeholder="email" maxlength=256 autocomplete="on">
					<div class="prettyFormErrorText" type="email"></div>
				</div>
			</div>
		</div>
		<div class="recoverPasswordButtonContainer">
			<button class="recoverPasswordButton">Email New Password</button>
		</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'click .recoverPasswordButton': '_performRecoverPasswordRequest'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @html
		return @


	_handleFormEntryChange: (event) =>
		if event.keyCode is 13
			@_performRecoverPasswordRequest()
		else
			attributesToSet = email: @$('.recoverPasswordEmail').val()
			@model.set attributesToSet, 
				error: (model, error) => console.error error


	_performRecoverPasswordRequest: () =>
		console.log '>> need to perform recover password request'


	_clearErrors: () =>
		@$('.prettyFormErrorText').removeClass 'visible'


	_showErrors: (errors) =>
		@_clearErrors()

		for errorType, errorText of errors
			errorField = @$(".prettyFormErrorText[type='#{errorType}']")
			errorField.addClass 'visible'
			errorField.html errorText

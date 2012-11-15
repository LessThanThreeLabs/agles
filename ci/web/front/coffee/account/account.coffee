window.Account = {}


class Account.Model extends Backbone.Model
	defaults:
		firstName: null
		lastName: null
		image: null

	initialize: () ->
		@set 'firstName', window.globalAccount.get 'firstName'
		@set 'lastName', window.globalAccount.get 'lastName'
		@set 'image', window.globalAccount.get 'image'


class Account.View extends Backbone.View
	tagName: 'div'
	className: 'account'
	template: Handlebars.compile '</div>
		<div class="prettyForm accountForm">
			<div class="prettyFormRow">
				<div class="prettyFormLabel">
					First Name
				</div>
				<div class="prettyFormValue">
					<input type="text" class="accountFirstNameField" placeholder="first" maxlength=64>
					<div class="prettyFormSaveText accountFirstNameSavedText">Saved</div>
					<div class="prettyFormErrorText accountFirstNameErrorText"></div>
				</div>
			</div>
			<div class="prettyFormEmptyRow"></div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">
					Last Name
				</div>
				<div class="prettyFormValue">
					<input type="text" class="accountLastNameField" placeholder="last" maxlength=64>
					<div class="prettyFormSaveText accountLastNameSavedText">Saved</div>
					<div class="prettyFormErrorText accountLastNameErrorText"></div>
				</div>
			</div>
			<div class="prettyFormEmptyRow"></div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">
					SSH Key
				</div>
				<div class="prettyFormValue">
					<textarea type="text" class="accountSshKeyField" placeholder="ssh key" maxlength=256></textarea>
					<div class="prettyFormSaveText accountSshKeySavedText">Saved</div>
					<div class="prettyFormErrorText accountSshKeyErrorText"></div>
				</div>
			</div>
		</div>'
	events: 
		'keyup': '_handleFormEntryChange'
		'blur .prettyFormValue': '_handleSubmitChange'

	initialize: () ->

	render: () ->
		@$el.html @template()
		return @


	_handleFormEntryChange: () =>
		@model.set 'firstName', @$el.find('.accountFirstNameField').val()
		@model.set 'lastName', @$el.find('.accountLastNameField').val()


	_handleSubmitChange: (event) =>
		console.log 'Need to submit account change!'

		errors = {}
		@_displayErrors errors
		@_showCorrectSavedMessage($(event.target)) if not errors? or Object.keys(errors).length is 0


	_showCorrectSavedMessage: (field) =>
		@$el.find('.accountFirstNameSavedText').hide()
		@$el.find('.accountLastNameSavedText').hide()
		@$el.find('.accountSshKeySavedText').hide()

		if field.hasClass 'accountFirstNameField'
			@$el.find('.accountFirstNameSavedText').show()
		if field.hasClass 'accountLastNameField'
			@$el.find('.accountLastNameSavedText').show()
		if field.hasClass 'accountSshKeyField'
			@$el.find('.accountSshKeySavedText').show()


	_clearErrors: () =>
		@_displayErrors {}


	_displayErrors: (errors = {}) =>
		firstNameError = @$el.find('.accountFirstNameErrorText')
		lastNameError = @$el.find('.accountLastNameErrorText')
		sshKeyError = @$el.find('.accountSshKeyErrorText')

		@_displayErrorForField firstNameError, errors.firstName
		@_displayErrorForField lastNameError, errors.lastName
		@_displayErrorForField sshKeyError, errors.sshKey


	_displayErrorForField: (errorView, errorText) =>
		if errorText?
			errorView.text errorText
			errorView.show()
		else
			errorView.text ''
			errorView.hide()

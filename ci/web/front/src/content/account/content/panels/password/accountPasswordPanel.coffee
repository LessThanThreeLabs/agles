window.AccountPasswordPanel = {}


class AccountPasswordPanel.Model extends Backbone.Model
	defaults:
		oldPassword: ''
		newPassword: ''
		confirmPassword: ''


	initialize: () =>
		@on 'change', () =>
			console.log @get 'oldPassword'
			console.log @get 'newPassword'
			console.log @get 'confirmPassword'


	validate: (attributes) =>
		if typeof attributes.oldPassword isnt 'string'
			return new Error 'Invalid old password: ' + attributes.oldPassword

		if typeof attributes.newPassword isnt 'string'
			return new Error 'Invalid new password: ' + attributes.newPassword

		if typeof attributes.confirmPassword isnt 'string'
			return new Error 'Invalid confirm password: ' + attributes.confirmPassword

		return	


class AccountPasswordPanel.View extends Backbone.View
	tagName: 'div'
	className: 'accountPasswordPanel'
	html: '<div class="prettyForm">
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Old password</div>
				<div class="prettyFormValue">
					<input type="password" class="accountOldPassword" placeholder="old password" maxlength=256>
					<div class="prettyFormErrorText" type="oldPassword"></div>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">New password</div>
				<div class="prettyFormValue">
					<input type="password" class="accountNewPassword" placeholder="new password" maxlength=256>
					<div class="prettyFormErrorText" type="newPassword"></div>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Confirm password</div>
				<div class="prettyFormValue">
					<input type="password" class="accountConfirmPassword" placeholder="new password, again" maxlength=256>
					<div class="prettyFormErrorText" type="confirmPassword"></div>
				</div>
			</div>
		</div>
		<div class="saveAccountPasswordButtonContainer">
			<button class="saveAccountPasswordButton">Save</button>
		</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'change .createAccountRememberMe': '_handleFormEntryChange'
		'click .saveAccountPasswordButton': '_performSaveAccountPasswordRequest'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @html
		return @


	_handleFormEntryChange: (event) =>
		if event.keyCode is 13
			@_performSaveAccountPasswordRequest()
		else
			attributesToSet =
				oldPassword: @$('.accountOldPassword').val()
				newPassword: @$('.accountNewPassword').val()
				confirmPassword: @$('.accountConfirmPassword').val()
			@model.set attributesToSet, 
				error: (model, error) => console.error error


	_performSaveAccountPasswordRequest: () =>
		console.log '>> need to save account password'

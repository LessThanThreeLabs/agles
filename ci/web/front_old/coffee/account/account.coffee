window.Account = {}


class Account.Model extends Backbone.Model
	defaults:
		firstName: null
		lastName: null
		# email: null
		sshKey: null
		alias: null


	initialize: () =>
		@updateAccountInformation()


	updateAccountInformation: () =>
		# @set 'email', globalAccount.get 'email'
		@set 'firstName', globalAccount.get 'firstName'
		@set 'lastName', globalAccount.get 'lastName'


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
					<div class="prettyFormErrorText accountLastNameErrorText"></div>
				</div>
			</div>


			<!--
			<div class="prettyFromEmptyRow"></div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">
					Email
				</div>
				<div class="prettyFormValue">
					<input type="text" class="accountEmailField" placeholder="email" maxlength=64>
					<div class="prettyFormErrorText accountEmailErrorText"></div>
				</div>
			</div>
			-->

				
			<div class="prettyFormEmptyRow"></div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel"></div>
				<div class="prettyFormValue">
					<button type="button" class="accountUpdateUserButton">Update User</button>
					<span class="prettyFormSaveText userUpdatedText">User successfully updated</span>
					<div class="prettyFormErrorText userUpdateErrorText"></div>
				</div>
			</div>
			<div class="prettyFormEmptyRow"></div>

			
			<div class="prettyFormRow">
				<div class="prettyFormLabel">
					Alias
				</div>
				<div class="prettyFormValue">	
					<input type="text" class="sshKeyAliasField" placeholder="alias" maxlength=64>
					<div class="prettyFormErrorText sshKeyAliasErrorText"></div>
				</div>
			</div>
			<div class="prettyFromEmptyRow"></div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">
					Key
				</div>
				<div class="prettyFormValue">
					<textarea type="text" class="sshKeyField" placeholder="key" maxlength=415></textarea>
					<div class="prettyFormErrorText sshKeyErrorText"></div>
				</div>
			</div>
			<div class="prettyFormEmptyRow"></div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel"></div>
				<div class="prettyFormValue">
					<button type="button" class="sshKeyAddButton">Add Key</button>
					<span class="prettyFormSaveText sshKeyAddedText">Key added</span>
					<div class="prettyFormErrorText sshKeyAddErrorText"></div>
				</div>
			</div>
		</div>'
	events: 
		'keyup': '_handleFormEntryChange'
		'click .accountUpdateUserButton': '_handleUserUpdate'
		'click .sshKeyAddButton': '_handleSshKeyAdd'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @template()
		@model.updateAccountInformation()
		@_syncViewToModel()		
		return @


	_syncViewToModel: () =>
		@$el.find('.accountFirstNameField').val @model.get 'firstName'
		@$el.find('.accountLastNameField').val @model.get 'lastName'
		# @$el.find('.accountEmailField').val @model.get 'email'
		@$el.find('.sshKeyField').val @model.get 'sshKey'
		@$el.find('.sshKeyAliasField').val @model.get 'alias'


	_handleFormEntryChange: () =>
		@model.set 'firstName', @$el.find('.accountFirstNameField').val()
		@model.set 'lastName', @$el.find('.accountLastNameField').val()
		# @model.set 'email', @$el.find('.accountEmailField').val()
		@model.set 'sshKey', @$el.find('.sshKeyField').val()
		@model.set 'alias', @$el.find('.sshKeyAliasField').val()


	_handleUserUpdate: (event) =>
		console.log 'this belongs in the model...'
		@_clearMessages()
		
		firstName = @model.get 'firstName'
		lastName = @model.get 'lastName'
		# email = @model.get 'email'

		args = 
			firstName: firstName
			lastName: lastName
			# email: email

		socket.emit 'users:update', args, (errors, result) =>
			if errors?
				@_displayErrors errors
			else
				@_showUserUpdatedMessage()
				window.globalAccount.set
					firstName: firstName
					lastName: lastName


	_showUserUpdatedMessage: () =>
		@$el.find('.userUpdatedText').css 'visibility', 'visible'


	_clearMessages: () =>
		@$el.find('.sshKeyAddedText').css 'visibility', 'hidden'
		@$el.find('.userUpdatedText').css 'visibility', 'hidden'
		@_displayErrors {}


	_displayErrors: (errors = {}) =>
		firstNameError = @$el.find('.accountFirstNameErrorText')
		lastNameError = @$el.find('.accountLastNameErrorText')
		# emailError = @$el.find('.accountEmailErrorText')
		userUpdateError = @$el.find('.userUpdateErrorText')
		sshKeyAliasError = @$el.find('.sshKeyAliasErrorText')
		sshKeyError = @$el.find('.sshKeyErrorText')
		sshKeyAddError = @$el.find('.sshKeyAddErrorText')

		@_displayErrorForField firstNameError, errors.firstName
		@_displayErrorForField lastNameError, errors.lastName
		# @_displayErrorForField emailError, errors.email
		@_displayErrorForField userUpdateError, errors.userUpdate
		@_displayErrorForField sshKeyAliasError, errors.alias
		@_displayErrorForField sshKeyError, errors.sshKey
		@_displayErrorForField sshKeyAddError, errors.sshKeyAdd


	_displayErrorForField: (errorView, errorText) =>
		if errorText?
			errorView.text errorText
			errorView.show()
		else
			errorView.text ''
			errorView.hide()


	_handleSshKeyAdd: (event) =>
		@_clearMessages()
		alias = @model.get 'alias'
		sshKey = @model.get 'sshKey'

		requestData =
			method: 'addSshKey'
			args:
				alias: alias
				sshKey: sshKey

		socket.emit 'users:update', requestData, (errors, result) =>
			if errors?
				@_displayErrors errors
			else
				@_sshKeyAdded()
				@model.set 'visible', false


	_sshKeyAdded: () =>
		@$el.find('.sshKeyAddedText').css 'visibility', 'visible'

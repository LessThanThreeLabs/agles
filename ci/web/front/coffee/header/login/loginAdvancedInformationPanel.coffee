window.LoginAdvancedInformationPanel = {}


class LoginAdvancedInformationPanel.Model extends Backbone.Model
	defaults:
		firstName: ''
		lastName: ''


class LoginAdvancedInformationPanel.View extends Backbone.View
	tagName: 'div'
	className: 'loginAdvancedInformationPanel'
	html: '<form class="form-horizontal">
			<div class="control-group firstNameControlGroup">
				<label class="control-label">First Name</label>
				<div class="controls loginFirstNameControls">
					<input type="text" class="loginFirstName" placeholder="first" maxlength=64 autocomplete="on">
					<span class="fieldError firstNameError help-inline"></span>
				</div>
			</div>

			<div class="control-group lastNameControlGroup">
				<label class="control-label">Last Name</label>
				<div class="controls loginLastNameControls">
					<input type="text" class="loginLastName" placeholder="last" maxlength=64 autocomplete="on">
					<span class="fieldError lastNameError help-inline"></span>
				</div>
			</div>
		</form>'
	events: 'keydown': '_handleFormEntryChange'


	initialize: () =>
		@model.on 'change:firstName', () =>
			$('.loginFirstName').val @model.get 'firstName'
		@model.on 'change:lastName', () =>
			$('.loginLastName').val @model.get 'lastName'


	onDispose: () =>
		@model.off null, null, @
		

	render: () =>
		@$el.html @html
		@clearErrors()
		return @


	_handleFormEntryChange: () =>
		setTimeout (() =>
			@model.set 'firstName', $('.loginFirstName').val()
			@model.set 'lastName', $('.loginLastName').val()
			), 0


	clear: () =>
		@clearFields()
		@clearErrors()


	clearFields: () =>
		@model.set
			firstName: ''
			lastName: ''


	clearErrors: () =>
		@displayErrors {}


	displayErrors: (errors = {}) =>
		if errors.firstName?
			 @_updateInvalidMessage $('.firstNameControlGroup'), $('.firstNameError'), true, errors.firstName
		else 
			@_updateInvalidMessage $('.firstNameControlGroup'), $('.firstNameError'), false

		if errors.lastName?
			@_updateInvalidMessage $('.lastNameControlGroup'), $('.lastNameError'), true, errors.lastName
		else 
			@_updateInvalidMessage $('.lastNameControlGroup'), $('.lastNameError'), false


	_updateInvalidMessage: (controlGroup, fieldError, visible, errorMessage) =>
		if visible
			controlGroup.addClass 'error'
			fieldError.text errorMessage
			fieldError.show()
		else
			controlGroup.removeClass 'error'
			fieldError.text ''
			fieldError.hide()

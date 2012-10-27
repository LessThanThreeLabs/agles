window.LoginAdvancedInformationPanel = {}


class LoginAdvancedInformationPanel.Model extends Backbone.Model
	defaults:
		firstName: ''
		lastName: ''


class LoginAdvancedInformationPanel.View extends Backbone.View
	tagName: 'div'
	className: 'loginAdvancedInformationPanel'
	template: Handlebars.compile '<form class="form-horizontal">
			<div class="control-group firstNameControlGroup">
				<label class="control-label">First Name</label>
				<div class="controls loginFirstNameControls">
					<input type="text" class="loginFirstName" placeholder="first" maxlength=64 autocomplete="on">
					<span class="firstNameError help-inline"></span>
				</div>
			</div>

			<div class="control-group lastNameControlGroup">
				<label class="control-label">Last Name</label>
				<div class="controls loginLastNameControls">
					<input type="text" class="loginLastName" placeholder="last" maxlength=64 autocomplete="on">
					<span class="lastNameError help-inline"></span>
				</div>
			</div>
		</form>'
	events:
		'keydown': '_handleFormEntryChange'

	render: () =>
		@$el.html @template()
		return @


	_handleFormEntryChange: () =>
		setTimeout (() =>
			@model.set 'firstName', $('.loginFirstName').val()
			@model.set 'lastName', $('.loginLastName').val()
			), 0


	updateInvalidFirstNameMessage: (visible, errorMessage) =>
		assert.ok errorMessage?

		if visible
			$('.firstNameControlGroup').addClass 'error'
			$('.firstNameError').text errorMessage
		else
			$('.firstNameControlGroup').removeClass 'error'
			$('.firstNameError').text ''


	updateInvalidPasswordMessage: (visible, errorMessage) =>
		assert.ok errorMessage?

		if visible
			$('.lastNameControlGroup').addClass 'error'
			$('.lastNameError').text errorMessage
		else
			$('.lastNameControlGroup').removeClass 'error'
			$('.lastNameError').text ''

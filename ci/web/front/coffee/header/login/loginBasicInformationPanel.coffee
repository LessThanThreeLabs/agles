window.LoginBasicInformationPanel = {}


class LoginBasicInformationPanel.Model extends Backbone.Model
	defaults:
		email: ''
		password: ''
		rememberMe: true


class LoginBasicInformationPanel.View extends Backbone.View
	tagName: 'div'
	className: 'loginBasicInformationPanel'
	template: Handlebars.compile '<form class="form-horizontal">
			<div class="control-group emailControlGroup">
				<label class="control-label">Email</label>
				<div class="controls loginEmailControls">
					<input type="email" class="loginEmail" placeholder="email" maxlength=256 autocomplete="on">
					<br><span class="fieldError emailError help-inline"></span>
				</div>
			</div>

			<div class="control-group passwordControlGroup">
				<label class="control-label">Password</label>
				<div class="controls loginPasswordControls">
					<input type="password" class="loginPassword" placeholder="password" maxlength=256>
					<br><span class="fieldError passwordError help-inline"></span>
				</div>
			</div>

			<div class="control-group">
				<div class="controls loginRememberMeControls">
					<label class="checkbox"><input type="checkbox" class="loginRemember"> Remember me</label>
				</div>
			</div>
		</form>'
	events:
		'keydown': '_handleFormEntryChange'
		'change .loginRemember': '_handleFormEntryChange'

	render: () =>
		@$el.html @template()
		@clearErrors()
		return @


	_handleFormEntryChange: () =>
		setTimeout (() =>
			@model.set 'email', $('.loginEmail').val()
			@model.set 'password', $('.loginPassword').val()
			@model.set 'rememberMe', $('.loginRemember').prop 'checked'
			), 0


	clearErrors: () =>
		@displayErrors {}


	displayErrors: (errors = {}) =>
		if errors.email?
			 @_updateInvalidMessage $('.emailControlGroup'), $('.emailError'), true, errors.email
		else 
			@_updateInvalidMessage $('.emailControlGroup'), $('.emailError'), false

		if errors.password?
			@_updateInvalidMessage $('.passwordControlGroup'), $('.passwordError'), true, errors.password
		else 
			@_updateInvalidMessage $('.passwordControlGroup'), $('.passwordError'), false


	_updateInvalidMessage: (controlGroup, fieldError, visible, errorMessage) =>
		if visible
			controlGroup.addClass 'error'
			fieldError.text errorMessage
			fieldError.show()
		else
			controlGroup.removeClass 'error'
			fieldError.text ''
			fieldError.hide()

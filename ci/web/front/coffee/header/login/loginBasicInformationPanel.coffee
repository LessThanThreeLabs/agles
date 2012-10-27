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
					<span class="emailError help-inline"></span>
				</div>
			</div>

			<div class="control-group passwordControlGroup">
				<label class="control-label">Password</label>
				<div class="controls loginPasswordControls">
					<input type="password" class="loginPassword" placeholder="password" maxlength=256>
					<span class="passwordError help-inline"></span>
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
		return @


	_handleFormEntryChange: () =>
		setTimeout (() =>
			@model.set 'email', $('.loginEmail').val()
			@model.set 'password', $('.loginPassword').val()
			@model.set 'rememberMe', $('.loginRemember').prop 'checked'
			), 0


	updateInvalidEmailMessage: (visible, errorMessage) =>
		assert.ok errorMessage?

		if visible
			$('.emailControlGroup').addClass 'error'
			$('.emailError').text errorMessage
		else
			$('.emailControlGroup').removeClass 'error'
			$('.emailError').text ''


	updateInvalidPasswordMessage: (visible, errorMessage) =>
		assert.ok errorMessage?

		if visible
			$('.passwordControlGroup').addClass 'error'
			$('.passwordError').text errorMessage
		else
			$('.passwordControlGroup').removeClass 'error'
			$('.passwordError').text ''

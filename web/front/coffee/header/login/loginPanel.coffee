window.LoginPanel = {}

# Since this panel is being added to the body, make sure it's only rendered once!
window.LoginPanel.renderedAlready = false


class LoginPanel.Model extends Backbone.Model
	defaults:
		visible: false

	initialize: () =>
		@loginPasswordColorHashModel = new LoginPasswordColorHash.Model()


	toggleVisibility: () =>
		@set 'visible', not @get('visible')


class LoginPanel.View extends Backbone.View
	tagName: 'div'
	className: 'loginPanel'
	template: Handlebars.compile '<div class="loginModal modal hide fade">
			<div class="modal-header">
				<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
				<h3>Login</h3>
			</div>
			<div class="modal-body">
				<form class="form-horizontal">
					<div class="control-group">
						<label class="control-label">Email</label>
						<div class="controls">
							<input type="text" class="loginEmail" placeholder="email">
						</div>
					</div>
					<div class="control-group">
						<label class="control-label">Password</label>
						<div class="controls loginPasswordControls">
							<input type="password" class="loginPassword" placeholder="password">
						</div>
					</div>
					<div class="control-group">
						<div class="controls">
							<label class="checkbox">
								<input type="checkbox"> Remember me
							</label>
						</div>
					</div>
				</form>
			</div>
			<div class="modal-footer">
				<a href="#" class="btn btn-primary">Login</a>
			</div>
		</div>'

	events:
		'keydown .loginPassword': '_handlePasswordChange'


	initialize: () =>
		@loginPasswordColorHashView = new  LoginPasswordColorHash.View model: @model.loginPasswordColorHashModel

		@model.on 'change:visible', @_updateVisibility

		$(document).on 'show', '.loginModal', () =>
			@model.set 'visible', true
		$(document).on 'hide', '.loginModal', () =>
			@model.set 'visible', false


	render: () =>
		assert.ok not window.LoginPanel.renderedAlready
		window.LoginPanel.renderedAlready = true

		@$el.html @template()
		@$el.find('.loginPasswordControls').append @loginPasswordColorHashView.render().el
		return @


	_handlePasswordChange: (event) =>
		setTimeout (() => @model.loginPasswordColorHashModel.set 'password', $('.loginPassword').val()), 0


	_updateVisibility: (model, visible) =>
		if visible then $('.loginModal').modal 'show'
		else $('.loginModal').modal 'hide'
		
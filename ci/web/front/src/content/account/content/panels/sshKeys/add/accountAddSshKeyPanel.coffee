window.AccountAddSshKeyPanel = {}


class AccountAddSshKeyPanel.Model extends Backbone.Model
	defaults:
		alias: ''
		key: ''


	reset: () =>
		attributesToSet =
			alias: ''
			key: ''
		@set attributesToSet,
			error: (model, error) => console.error error


	validate: (attributes) =>
		if typeof attributes.alias isnt 'string'
			return new Error 'Invalid alias: ' + attributes.alias

		if typeof attributes.key isnt 'string'
			return new Error 'Invalid key: ' + attributes.key

		return


class AccountAddSshKeyPanel.View extends Backbone.View
	tagName: 'div'
	className: 'accountAddSshKeyPanel'
	html: '<div class="prettyForm">
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Alias</div>
				<div class="prettyFormValue">
					<input type="text" class="sshKeyAlias" placeholder="alias" maxlength=64 autocomplete="on">
					<div class="prettyFormErrorText" type="alias"></div>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Key</div>
				<div class="prettyFormValue">
					<textarea type="text" class="sshKey" placeholder="key" maxlength=256></textarea>
					<div class="prettyFormErrorText" type="key"></div>
				</div>
			</div>
		</div>
		<div class="addKeyButtonContainer">
			<button class="addKeyButton">Add</button>
		</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'click .addKeyButton': '_performAddKeyRequest'


	initialize: () =>
		@model.on 'change', () =>
			@$('.sshKeyAlias').val @model.get 'alias'
			@$('.sshKey').val @model.get 'key'


	onDispose: () =>


	render: () =>
		@$el.html @html
		@correctFocus()
		return @


	correctFocus: () =>
		setTimeout (() => @$('.sshKeyAlias').focus()), 0


	_handleFormEntryChange: (event) =>
		attributesToSet = 
			alias: @$('.sshKeyAlias').val()
			key: @$('.sshKey').val()
		@model.set attributesToSet,
			error: (model, error) => console.error error


	_performAddKeyRequest: () =>
		requestData = 
			method: 'addSshKey'
			args:
				alias: @model.get 'alias'
				sshKey: @model.get 'key'

		socket.emit 'users:update', requestData, (errors, result) =>
			if error?
				@_showErrors errors
			else
				@trigger 'addedKey'
				globalNotificationManager.addNotification PrettyNotification.Types.SUCCESS, 'SSH key added'


	_clearErrors: () =>
		@$('.prettyFormErrorText').removeClass 'visible'


	_showErrors: (errors) =>
		@_clearErrors()

		if typeof errors is 'string'
			globalNotificationManager.addNotification PrettyNotification.Types.ERROR, errors
			return

		for errorType, errorText of errors
			errorField = @$(".prettyFormErrorText[type='#{errorType}']")
			errorField.addClass 'visible'
			errorField.html errorText

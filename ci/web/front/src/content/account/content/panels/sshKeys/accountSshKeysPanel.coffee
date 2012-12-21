window.AccountSshKeysPanel = {}


class AccountSshKeysPanel.Model extends Backbone.Model
	defaults:
		alias: ''
		key: ''


	validate: (attributes) =>
		if typeof attributes.alias isnt 'string'
			return new Error 'Invalid alias: ' + attributes.alias

		if typeof attributes.key isnt 'string'
			return new Error 'Invalid key: ' + attributes.key

		return


class AccountSshKeysPanel.View extends Backbone.View
	tagName: 'div'
	className: 'accountSshKeysPanel'
	html: '<div class="accountSshKeysPanelContent">
			<div class="prettyForm">
				<div class="prettyFormRow">
					<div class="prettyFormLabel">Alias</div>
					<div class="prettyFormValue">
						<input type="text" class="accountSshKeyAlias" placeholder="alias" maxlength=256>
						<div class="prettyFormErrorText" type="alias"></div>
					</div>
				</div>
				<div class="prettyFormRow">
					<div class="prettyFormLabel">Key</div>
					<div class="prettyFormValue">
						<textarea type="text" class="accountSshKey" placeholder="key" maxlength=500></textarea>
						<div class="prettyFormErrorText" type="key"></div>
					</div>
				</div>
			</div>
			<div class="saveAccountSshKeyButtonContainer">
				<button class="saveAccountSshKeyButton">Save</button>
			</div>
		</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'click .saveAccountSshKeyButton': '_performSaveAccountSshKeyRequest'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @html
		setTimeout (() => @$('.accountSshKeyAlias').focus()), 0
		return @


	_handleFormEntryChange: (event) =>
		if event.keyCode is 13
			@_performSaveAccountSshKeyRequest()
		else
			attributesToSet =
				alias: @$('.accountSshKeyAlias').val()
				key: @$('.accountSshKey').val()
			@model.set attributesToSet, 
				error: (model, error) => console.error error


	_performSaveAccountSshKeyRequest: () =>
		console.log '>> need to save ssh key'


	_clearErrors: () =>
		@$('.prettyFormErrorText').removeClass 'visible'


	_showErrors: (errors) =>
		@_clearErrors()

		for errorType, errorText of errors
			errorField = @$(".prettyFormErrorText[type='#{errorType}']")
			errorField.addClass 'visible'
			errorField.html errorText

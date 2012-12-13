window.RepositoryAdminInviteMembersPanel = {}


class RepositoryAdminInviteMembersPanel.Model extends Backbone.Model
	defaults:
		emails: null


class RepositoryAdminInviteMembersPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminInviteMembersPanel'
	html: '<div class="inviteForm">
			<div class="inviteMembersFieldContainer">
				<input type="text" class="inviteMembersField" placeholder="emails">
			</div>
			<div class="inviteButtonContainer">
				<button class="inviteButton">Invite</button>
			</div>
		</div>
		<div class="repositoryInviteMembersSentText">Emails sent</div>
		<div class="repositoryInviteMembersErrorText"></div>
		<div class="inviteMembersHint">Separate multiple email addresses with commas</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'click .inviteButton': '_handleSubmit'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @html
		return @


	_handleFormEntryChange: (event) =>
		@_handleSubmit event if event.keyCode is 13 # enter key
		@model.set 'emails', @_parseEmails @$el.find('.inviteMembersField').val()


	_parseEmails: (emails) =>
		email.trim() for email in emails.split ','


	_clearForm: () =>
		@$el.find('.inviteMembersField').val ''


	_handleSubmit: (event) =>
		@_clearForm()
		emails = @model.get 'emails'
		requestData =
			method: 'inviteMembers'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'
				emails: emails

		socket.emit 'repos:update', requestData, (errors, result) =>
			if errors?
				globalRouterModel.set 'view', 'invalidRepositoryState' if errors is 403
				@_displayErrors errors
			showSentMessage = not errors? or Object.keys(errors).length < emails.length
			@$el.find('.repositoryInviteMembersSentText').toggle showSentMessage


	_clearErrors: () =>
		@_displayErrors []


	_displayErrors: (errors) =>
		inviteMembersError = @$el.find('.repositoryInviteMembersErrorText')
		@_displayErrorForField inviteMembersError, @_getErrorText errors


	_getErrorText: (errors) =>
		if Object.keys(errors).length > 0
			'Couldn\'t invite users: ' + errors.join ', '


	_displayErrorForField: (errorView, errorText) =>
		if errorText?
			errorView.text errorText
			errorView.show()
		else
			errorView.text ''
			errorView.hide()

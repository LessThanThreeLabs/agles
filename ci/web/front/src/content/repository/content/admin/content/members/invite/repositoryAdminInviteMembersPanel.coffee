window.RepositoryAdminInviteMembersPanel = {}


class RepositoryAdminInviteMembersPanel.Model extends Backbone.Model
	defaults:
		emails: null


	inviteMembers: (callback) =>
		requestData =
			method: 'inviteMembers'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'
				emails: @_cleanEmails @get 'emails'

		socket.emit 'repos:update', requestData, callback


	_cleanEmails: (emails) =>
		email.trim() for email in emails.split ','


class RepositoryAdminInviteMembersPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminInviteMembersPanel'
	html: '<div class="inviteForm">
			<input type="text" class="inviteMembersField" placeholder="alice@awesome.com, bob@awesome.com, eve@awesome.com">
			<button class="inviteButton">Invite</button>
		</div>
		<div class="repositoryInviteMembersSentText">Emails sent</div>
		<div class="repositoryInviteMembersErrorText"></div>'
	events:
		'keyup': '_handleFormEntryChange'
		'click .inviteButton': '_handleInviteUsers'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @html
		setTimeout (() => @$('.inviteMembersField').focus()), 0
		return @


	_handleFormEntryChange: () =>
		if event.keyCode is 13
			@_handleInviteUsers()
		else
			@model.set 'emails', @$('.inviteMembersField').val(),
				error: (model, error) => console.error error


	_handleInviteUsers: (event) =>
		@_clearForm()
		@model.inviteMembers (error, result) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				@_showErrorMessage true, @_toErrorMessage error
			else
				@_showSuccessMessage true


	_clearForm: () =>
		@$('.inviteMembersField').val ''
		@_showSuccessMessage false
		@_showErrorMessage false


	_showSuccessMessage: (showSuccess) =>
		@$('.repositoryInviteMembersSentText').toggle showSuccess


	_toErrorMessage: (emails) =>
		if emails?
			'Unable to invite: ' + emails.join(', ')


	_showErrorMessage: (showError, message) =>
		if showError
			@$('.repositoryInviteMembersErrorText').text message
			@$('.repositoryInviteMembersErrorText').show()
		else
			@$('.repositoryInviteMembersErrorText').text ''
			@$('.repositoryInviteMembersErrorText').hide()

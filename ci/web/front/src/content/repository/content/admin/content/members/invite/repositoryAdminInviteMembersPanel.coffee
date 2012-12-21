window.RepositoryAdminInviteMembersPanel = {}


class RepositoryAdminInviteMembersPanel.Model extends Backbone.Model
	defaults:
		emails: null


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
		console.log '>> Need to invite members to repository!'


	_showSuccessMessage: (showSuccess) =>
		@$('.repositoryInviteMembersSentText').toggle showSuccess


	_showErrorMessage: (showError, message) =>
		if showError
			@$('.repositoryInviteMembersErrorText').text message
			@$('.repositoryInviteMembersErrorText').show()
		else
			@$('.repositoryInviteMembersErrorText').text ''
			@$('.repositoryInviteMembersErrorText').hide()

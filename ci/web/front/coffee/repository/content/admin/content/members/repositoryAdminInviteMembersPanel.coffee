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


	_handleFormEntryChange: () =>
		@model.set 'emails', @$el.find('.inviteMembersField').val()


	_handleSubmit: (event) =>
		console.log 'Need to submit repository change!'

		errors = invite: 'Couldnt invite the peoples'
		@_displayErrors errors

		showSentMessage = not errors? or Object.keys(errors).length is 0
		@$el.find('.repositoryInviteMembersSentText').toggle showSentMessage


	_clearErrors: () =>
		@_displayErrors {}


	_displayErrors: (errors = {}) =>
		inviteMembersError = @$el.find('.repositoryInviteMembersErrorText')
		@_displayErrorForField inviteMembersError, errors.invite


	_displayErrorForField: (errorView, errorText) =>
		if errorText?
			errorView.text errorText
			errorView.show()
		else
			errorView.text ''
			errorView.hide()

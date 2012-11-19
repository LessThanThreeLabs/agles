window.RepositoryAdminInviteMembersPanel = {}


class RepositoryAdminInviteMembersPanel.Model extends Backbone.Model
	defaults:
		repositoryId: null
		emails: null

	initialize: () ->
		@on 'change:emails', () =>
			console.log @get 'emails'


class RepositoryAdminInviteMembersPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminInviteMembersPanel'
	template: Handlebars.compile '<div class="inviteForm">
			<div class="inviteMembersFieldContainer">
				<input type="text" class="inviteMembersField" placeholder="emails">
			</div>
			<div class="inviteButtonContainer">
				<button class="inviteButton">Invite</button>
			</div>
		</div>
		<div class="prettyFormErrorText repositoryInviteMembersErrorText"></div>
		<div class="inviteMembersHint">Separate multiple email addresses with commas</div>'
	events: 
		'keyup': '_handleFormEntryChange'
		'click .inviteButton': '_handleSubmit'

	initialize: () =>

	render: () =>
		@$el.html @template()
		return @


	_handleFormEntryChange: () =>
		@model.set 'emails', @$el.find('.inviteMembersField').val()


	_handleSubmit: (event) =>
		console.log 'Need to submit repository change!'

		errors = invite: 'couldnt invite the peoples'
		@_displayErrors errors

		console.log 'tell the user which were successful'


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

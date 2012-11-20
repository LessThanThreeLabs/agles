window.RepositoryAdminMembersPanel = {}


class RepositoryAdminMembersPanel.Model extends Backbone.Model
	defaults:
		repositoryId: null

	initialize: () ->
		@inviteMembersPanelModel = new RepositoryAdminInviteMembersPanel.Model()
		@memberPermissionsPanelModel = new RepositoryAdminMemberPermissionsPanel.Model()


class RepositoryAdminMembersPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminMembersPanel'
	template: Handlebars.compile '<div class="inviteMembers">
			<div class="inviteMembersTitle">Invite Members</div>
			<div class="inviteMembersContent"></div>
		</div>
		<div class="memberPermissions">
			<div class="memberPermissionsTitle">Member Permissions</div>
			<div class="memberPermissionsContent"></div>
		</div>'
	# events: 
	# 	'keyup': '_handleFormEntryChange'
	# 	'blur .prettyFormValue': '_handleSubmitChange'

	initialize: () =>

	render: () =>
		@$el.html @template()

		inviteMembersPanelView = new RepositoryAdminInviteMembersPanel.View model: @model.inviteMembersPanelModel
		@$el.find('.inviteMembersContent').html inviteMembersPanelView.render().el

		memberPermissionsPanelView = new RepositoryAdminMemberPermissionsPanel.View model: @model.memberPermissionsPanelModel
		@$el.find('.memberPermissionsContent').html memberPermissionsPanelView.render().el

		return @
		
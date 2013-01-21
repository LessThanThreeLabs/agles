window.RepositoryAdminMembersPanel = {}


class RepositoryAdminMembersPanel.Model extends Backbone.Model

	initialize: () =>
		@inviteMembersPanelModel = new RepositoryAdminInviteMembersPanel.Model()
		@memberPermissionsPanelModel = new RepositoryAdminMemberPermissionsPanel.Model()


class RepositoryAdminMembersPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminMembersPanel'
	html: '<div class="inviteMembers">
			<div class="inviteMembersTitle">Invite Members</div>
			<div class="inviteMembersContent"></div>
		</div>
		<div class="memberPermissions">
			<div class="memberPermissionsTitle">Member Permissions</div>
			<div class="memberPermissionsContent"></div>
		</div>'


	initialize: () =>
		@inviteMembersPanelView = new RepositoryAdminInviteMembersPanel.View model: @model.inviteMembersPanelModel
		@memberPermissionsPanelView = new RepositoryAdminMemberPermissionsPanel.View model: @model.memberPermissionsPanelModel


	onDispose: () =>
		@inviteMembersPanelView.dispose()
		@memberPermissionsPanelView.dispose()


	render: () =>
		@$el.html @html
		@$('.inviteMembersContent').html @inviteMembersPanelView.render().el
		@$('.memberPermissionsContent').html @memberPermissionsPanelView.render().el
		return @

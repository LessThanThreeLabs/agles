window.RepositoryAdminMemberPermissionsPanel = {}


class RepositoryAdminMemberPermissionsPanel.Model extends Backbone.Model

	initialize: () =>
		@memberPermissionsModels = new Backbone.Collection()
		@memberPermissionsModels.model = MemberPermissions.Model
		@memberPermissionsModels.comparator = (memberPermissionsModel) =>
			return memberPermissionsModel.get 'email'
		@memberPermissionsModels.on 'removeMember', (memberPermissionsModel) =>
			@memberPermissionsModels.remove memberPermissionsModel


	fetchMembers: () =>
		@memberPermissionsModels.reset()
		return if not globalRouterModel.get('repositoryId')?

		requestData =
			method: 'getMembersWithPermissions'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'

		socket.emit 'repos:read', requestData, (errors, users) =>
			if errors?
				console.log errors
				console.error "Could not read member permissions"
			else
				@memberPermissionsModels.reset()
				@memberPermissionsModels.add users


class RepositoryAdminMemberPermissionsPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminMemberPermissionsPanel'
	html: '<div class="prettyTable permissionsTable">
			<div class="prettyTableTitleRow">
				<div class="prettyTableColumn">Email</div>
				<div class="prettyTableColumn">First Name</div>
				<div class="prettyTableColumn">Last Name</div>
				<div class="prettyTableColumn readPermissionColumn">R</div>
				<div class="prettyTableColumn readWritePermissionColumn">R/W</div>
				<div class="prettyTableColumn readWriteAdminPermissionColumn">R/W/A</div>
				<div class="prettyTableColumn removeMemberColumn">Remove</div>
			</div>
		</div>'


	initialize: () =>
		@model.memberPermissionsModels.on 'add', @_handleAdd, @
		@model.memberPermissionsModels.on 'reset', @render, @
		@model.memberPermissionsModels.on 'remove', @render, @
		globalRouterModel.on 'change:repositoryId', @model.fetchMembers, @

		@model.fetchMembers()


	onDispose: () =>
		@model.memberPermissionsModels.off null, null, @
		globalRouterModel.off null, null, @


	render: () =>
		@$el.html @html
		@_addCurrentMembers()
		return @


	_addCurrentMembers: () =>
		@model.memberPermissionsModels.each (memberPermissionsModel) =>
			memberPermissionView = new MemberPermissions.View model: memberPermissionsModel
			@$el.find('.permissionsTable').append memberPermissionView.render().el


	_handleAdd: (memberPermissionsModel, collection, options) =>
		memberPermissionView = new MemberPermissions.View model: memberPermissionsModel
		@_insertMemberAtIndex memberPermissionView.render().el, options.index


	_insertMemberAtIndex: (memberPermissionView, index) =>
		memberPermissionRowsOffset = 2

		if index is 0
			@$el.find('.permissionsTable').append memberPermissionView
		else
			@$el.find('.permissionsTable .memberPermissions:nth-child('+ (index+1) + ')').after memberPermissionView


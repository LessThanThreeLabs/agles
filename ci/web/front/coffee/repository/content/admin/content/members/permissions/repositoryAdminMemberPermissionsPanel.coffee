window.RepositoryAdminMemberPermissionsPanel = {}


class RepositoryAdminMemberPermissionsPanel.Model extends Backbone.Model
	subscribeUrl: 'repos'
	subscribeId: null

	initialize: () =>
		@subscribeId = globalRouterModel.get 'repositoryId'

		@memberPermissionsModels = new Backbone.Collection()
		@memberPermissionsModels.model = MemberPermissions.Model
		@memberPermissionsModels.comparator = (memberPermissionsModel) =>
			return memberPermissionsModel.get 'email'


	fetchMembers: () =>
		@memberPermissionsModels.reset()
		return if not globalRouterModel.get('repositoryId')?

		requestData =
			method: 'getMembersWithPermissions'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'

		socket.emit 'repos:read', requestData, (errors, users) =>
			if errors?
				globalRouterModel.set 'view', 'invalidRepositoryState' if errors is 403
				console.error errors
			else
				@memberPermissionsModels.reset users


	onUpdate: (data) =>
		console.log data
		assert.ok data.type?

		if data.type is 'member added'
			assert.ok data.contents.email? and data.contents.firstName? and
				data.contents.lastName? and data.contents.permissions?
			memberPermissionsModel = new MemberPermissions.Model data.contents
			@memberPermissionsModels.add memberPermissionsModel
		else if data.type is 'member removed'
			assert.ok data.contents.email?
			@memberPermissionsModels.remove @memberPermissionsModels.where {email: data.contents.email}
		else if data.type is 'member permissions changed'
			assert.ok data.contents.email? and data.contents.permissions?
			@memberPermissionsModels.where({email: data.contents.email})[0].set 'permissions', data.contents.permissions
		else
			console.log 'Unaccounted for update type: ' + data.type


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
		globalRouterModel.on 'change:repositoryId', (() =>
			@model.unsubscribe() if @model.subscribeId?
			@model.subscribeId = globalRouterModel.get 'repositoryId'
			@model.subscribe() if @model.subscribeId?
			console.log 'resubscribed'
			@model.fetchMembers), @

		@model.subscribe() if @model.subscribeId?
		@model.fetchMembers()


	onDispose: () =>
		@model.unsubscribe() if @model.subscribeId?
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


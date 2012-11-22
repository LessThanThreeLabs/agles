window.RepositoryAdminMemberPermissionsPanel = {}


class RepositoryAdminMemberPermissionsPanel.Model extends Backbone.Model
	defaults:
		repositoryId: null
		# will need users here...

	initialize: () =>
		@memberPermissionsModels = new Backbone.Collection()
		@memberPermissionsModels.model = MemberPermissions.Model
		@memberPermissionsModels.comparator = (memberPermissionsModel) =>
			return memberPermissionsModel.get 'email'


	fetchMembersIfNecassary: () =>
		# DON'T FETCH MEMBERS IF MEMBERS HAVE BEEN FETCHED BEFORE!!!!
		console.log 'need to fetch members'

		member1 =
			email: 'cc.fake@email.com'
			firstName: 'fake'
			lastName: 'email'
			permissions: 'r'
		member2 =
			email: 'aa.fake@email2.com'
			firstName: 'faker'
			lastName: 'email'
			permissions: 'r/w'
		member3 =
			email: 'bb.fake@email2.com'
			firstName: 'faker'
			lastName: 'email'
			permissions: 'r/w'

		@memberPermissionsModels.add [member1, member2]

		setTimeout (() =>
				@memberPermissionsModels.add [member3]			
			), 1000


class RepositoryAdminMemberPermissionsPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminMemberPermissionsPanel'
	template: Handlebars.compile '<div class="prettyTable permissionsTable">
			<div class="prettyTableTitleRow">
				<div class="prettyTableColumn">Email</div>
				<div class="prettyTableColumn">First Name</div>
				<div class="prettyTableColumn">Last Name</div>
			</div>
		</div>'

	initialize: () =>
		@model.memberPermissionsModels.on 'add', (memberPermissionsModel, collection, options) =>
			memberPermissionView = new MemberPermissions.View model: memberPermissionsModel
			@_insertBuildAtIndex memberPermissionView.render().el, options.index
		@model.memberPermissionsModels.on 'reset', () =>
			@$el.html @template()


	render: () =>
		@$el.html @template()
		@model.fetchMembersIfNecassary()
		return @


	_insertBuildAtIndex: (memberPermissionView, index) =>
		memberPermissionRowsOffset = 2

		if index is 0
			@$el.find('.permissionsTable').append memberPermissionView
		else
			@$el.find('.permissionsTable .memberPermissions:nth-child('+ (index+1) + ')').after memberPermissionView

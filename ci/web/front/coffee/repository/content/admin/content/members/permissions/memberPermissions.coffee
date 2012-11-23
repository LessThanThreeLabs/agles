window.MemberPermissions = {}


class MemberPermissions.Model extends Backbone.Model
	ALLOWED_PERMISSIONS: ['r', 'r/w', 'r/w/a']

	defaults:
		email: null
		firstName: null
		lastName: null
		permissions: null


	validate: (attributes) =>
		if attributes.permissions not in @ALLOWED_PERMISSIONS
			return new Error 'Invalid member permissions'
		return


class MemberPermissions.View extends Backbone.View
	tagName: 'div'
	className: 'memberPermissions prettyTableRow'
	template: Handlebars.compile '
		<div class="prettyTableColumn">{{email}}</div>
		<div class="prettyTableColumn">{{firstName}}</div>
		<div class="prettyTableColumn">{{lastName}}</div>
		<div class="prettyTableColumn permissionsRadio"><input type="radio" value="r" name="{{email}}PermissionsRadio"></div>
		<div class="prettyTableColumn permissionsRadio"><input type="radio" value="r/w" name="{{email}}PermissionsRadio"></div>
		<div class="prettyTableColumn permissionsRadio"><input type="radio" value="r/w/a" name="{{email}}PermissionsRadio"></div>'
	events:
		'change .permissionsRadio': '_handlePermissionsChange'

	initialize: () =>

	render: () =>
		@$el.html @template
			email: @model.get 'email'
			firstName: @model.get 'firstName'
			lastName: @model.get 'lastName'
		@_selectCorrectPermissionsRadio()
		return @


	_selectCorrectPermissionsRadio: () =>
		@$el.find('input:radio[value="' + @model.get('permissions') + '"]').prop 'checked', true


	_handlePermissionsChange: (event) =>
		permissions = $(event.target).val()
		console.log 'need to change member permissions to: ' + permissions

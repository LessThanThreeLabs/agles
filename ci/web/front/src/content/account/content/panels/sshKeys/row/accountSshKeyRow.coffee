window.AccountSshKeysRow = {}


class AccountSshKeysRow.Model extends Backbone.Model
	defaults:
		alias: ''
		dateAdded: ''


	validate: (attributes) =>
		if typeof attributes.alias isnt 'string'
			return new Error 'Invalid alias: ' + attributes.alias

		if typeof attributes.dateAdded isnt 'string'
			return new Error 'Invalid date added: ' + attributes.dateAdded

		return


	removeKey: () =>
		console.log '>> need to remove key...'


class AccountSshKeysRow.View extends Backbone.View
	tagName: 'div'
	className: 'accountSshKeysRow prettyTableRow'
	template: Handlebars.compile '
		<div class="prettyTableColumn">{{alias}}</div>
		<div class="prettyTableColumn">{{dateAdded}}</div>
		<div class="prettyTableColumn removeKeyColumn"><img src="/img/icons/removeMember.svg" class="removeKeyImage"></div>'
	events:
		'click .removeKeyImage': '_handleRemoveKey'

	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @template
			alias: @model.get 'alias'
			dateAdded: @model.get 'dateAdded'
		return @


	_handleRemoveKey: () =>
		@model.removeKey()

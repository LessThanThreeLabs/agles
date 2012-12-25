window.AccountCurrentSshKeysPanel = {}


class AccountCurrentSshKeysPanel.Model extends Backbone.Model

	initialize: () =>
		@sshKeyRowModels = new Backbone.Collection()
		@sshKeyRowModels.model = AccountSshKeysRow.Model
		@sshKeyRowModels.comparator = (sshKeyRowModel) =>
			return sshKeyRowModel.get 'alias'


	fetchKeys: () =>
		@sshKeyRowModels.reset()

		console.log 'need to retrieve ssh keys....'
		blah1 =
			alias: 'hello'
			dateAdded: 'some date here'
		blah2 =
			alias: 'hello again'
			dateAdded: 'some other date here'
		blah3 =
			alias: 'hello again again'
			dateAdded: 'some other date here yar'
		blah4 =
			alias: 'hello again again again again'
			dateAdded: 'some other date here hooray'

		setTimeout (() =>
			@sshKeyRowModels.reset [blah1, blah2, blah3, blah4],
				error: (model, error) => console.error error
			), 500


class AccountCurrentSshKeysPanel.View extends Backbone.View
	tagName: 'div'
	className: 'accountCurrentSshKeysPanel'
	html: '<div class="prettyTable sshKeysTable">
			<div class="prettyTableTitleRow">
				<div class="prettyTableColumn aliasColumn">Alias</div>
				<div class="prettyTableColumn createdDateColumn">Created</div>
				<div class="prettyTableColumn removeKeyColumn">Remove</div>
			</div>
		</div>'


	initialize: () =>
		@model.sshKeyRowModels.on 'add', @_handleAdd, @
		@model.sshKeyRowModels.on 'reset', @render, @

		# TODO: make this smarter... (like handleAdd)
		@model.sshKeyRowModels.on 'remove', @render, @

		@model.fetchKeys()


	onDispose: () =>
		@model.sshKeyRowModels.off null, null, @


	render: () =>
		@$el.html @html
		@_addCurrentKeys()
		return @


	_addCurrentKeys: () =>
		@model.sshKeyRowModels.each (sshKeyRowModel) =>
			sshKeyRowView = new AccountSshKeysRow.View model: sshKeyRowModel
			@$('.sshKeysTable').append sshKeyRowView.render().el


	_handleAdd: (sshKeyRowModel, collection, options) =>
		sshKeyRowView = new AccountSshKeysRow.View model: sshKeyRowModel
		@_insertSshKeyAtIndex sshKeyRowView.render().el, options.index


	_insertSshKeyAtIndex: (sshKeyRowView, index) =>
		if index is 0
			@$el.find('.sshKeysTable').append sshKeyRowView
		else
			@$el.find('.sshKeysTable .accountSshKeysRow:nth-child('+ (index+1) + ')').after sshKeyRowView


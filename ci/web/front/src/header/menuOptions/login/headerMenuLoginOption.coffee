window.HeaderMenuLoginOption = {}


class HeaderMenuLoginOption.Model extends Backbone.Model
	VALID_STATES: ['login', 'create']
	defaults:
		visible: false


	initialize: () =>
		@loginPanelModel = new LoginPanel.Model()
		@modalModel = new PrettyModal.Model()


	updateInformation: () =>
		attributesToSet = visible: globalAccount.get('email')?
		@set attributesToSet, error: (model, error) => console.error error


	validate: (attributes) =>
		if typeof attributes.visible isnt 'boolean'
			return new Error 'Invalid visibility: ' + attributes.visible

		return


class HeaderMenuLoginOption.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenuLoginOption headerMenuOption'
	html: '<div class="headerMenuOptionTitle">Login</div>'
	events: 'click': '_clickHandler'
	currentView: null


	initialize: () =>
		@loginPanelView = new LoginPanel.View model: @model.loginPanelModel
		@modalView = new PrettyModal.View model: @model.modalModel

		@model.on 'change:visible', @_fixVisibility, @
		globalAccount.on 'change', @model.updateInformation, @

		@loginPanelView.on 'loggedIn', () =>
			@model.modalModel.set 'visible', false

		@model.updateInformation()


	onDispose: () =>
		@model.off null, null, @
		globalAccount.off null, null, @

		@loginPanelView.dispose()
		@modalView.dispose()


	render: () =>
		@$el.html @html
		@$el.append @modalView.render().el
		@modalView.setInnerHtml @loginPanelView.render().el
		@_fixVisibility()
		return @


	_fixVisibility: () =>
		@$el.css 'display', if @model.get('visible') then 'inline-block' else 'none'


	_clickHandler: () =>
		@model.modalModel.set 'visible', true
		
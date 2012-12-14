window.LoginHeaderMenuOption = {}


class LoginHeaderMenuOption.Model extends Backbone.Model
	defaults:
		visible: false


	initialize: () =>
		@modalModel = new PrettyModal.Model()


	updateInformation: () =>
		# @set 'visible', not globalAccount.get('email')?
		@set 'visible', globalAccount.get('email')?


class LoginHeaderMenuOption.View extends Backbone.View
	tagName: 'div'
	className: 'loginHeaderMenuOption headerMenuOption'
	html: '<div class="headerMenuOptionTitle">Login</div>'
	events: 'click': '_clickHandler'


	initialize: () =>
		@modalView = new PrettyModal.View model: @model.modalModel
		@modalView.setInnerHtml 'hello there!'

		@model.on 'change', @render, @
		globalAccount.on 'change', @model.updateInformation, @

		@model.updateInformation()


	onDispose: () =>
		@model.off null, null, @
		globalAccount.off null, null, @


	render: () =>
		@$el.html @html
		@$el.append @modalView.render().el
		@_fixVisibility()
		return @


	_fixVisibility: () =>
		@$el.css 'display', if @model.get('visible') then 'inline-block' else 'none'


	_clickHandler: () =>
		@model.modalModel.set 'visible', true
		
window.LoginHeaderMenuOption = {}


class LoginHeaderMenuOption.Model extends Backbone.Model
	defaults:
		visible: false


	updateInformation: () =>
		@set 'visible', not globalAccount.get('email')?


class LoginHeaderMenuOption.View extends Backbone.View
	tagName: 'div'
	className: 'loginHeaderMenuOption headerMenuOption'
	html: '<div class="headerMenuOptionTitle">Login</div>'
	events: 'click': '_clickHandler'


	initialize: () =>
		@model.on 'change', @render, @
		globalAccount.on 'change', @model.updateInformation, @

		@model.updateInformation()


	onDispose: () =>
		@model.off null, null, @
		globalAccount.off null, null, @


	render: () =>
		@$el.html @html
		@_fixVisibility()
		return @


	_fixVisibility: () =>
		@$el.css 'display', if @model.get('visible') then 'inline-block' else 'none'


	_clickHandler: () =>
		console.log 'need to handle login click'
		
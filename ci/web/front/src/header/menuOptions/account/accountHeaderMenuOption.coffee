window.AccountHeaderMenuOption = {}


class AccountHeaderMenuOption.Model extends Backbone.Model
	PROFILE_DROPDOWN_OPTION: new PrettyDropdownOption('profile', 'Profile')
	LOGOUT_DROPDOWN_OPTION: new PrettyDropdownOption('logout', 'Logout')
	defaults:
		firstName: null
		lastName: null
		visible: false


	initialize: () =>
		dropdownOptions = [@PROFILE_DROPDOWN_OPTION, @LOGOUT_DROPDOWN_OPTION]
		@dropdownModel = new PrettyDropdown.Model 
			options: dropdownOptions
			alignment: 'right'


	updateInformation: () =>
		@set 'firstName', globalAccount.get 'firstName'
		@set 'lastName', globalAccount.get 'lastName'
		@set 'visible', globalAccount.get('email')?


class AccountHeaderMenuOption.View extends Backbone.View
	tagName: 'div'
	className: 'accountHeaderMenuOption headerMenuOption'
	html: '<div class="headerMenuOptionTitle">
			<span class="accountHeaderFirstName"></span>
			<span class="accountHeaderLastName"></span>
		</div>'
	events: 'click .headerMenuOptionTitle': '_handleClick'


	initialize: () =>
		@dropdownView = new PrettyDropdown.View model: @model.dropdownModel
		@dropdownView.on 'selected', @_handleDropdownSelection, @

		@model.on 'change:firstName change:lastName', @_fixName, @
		@model.on 'change:visible', @_fixVisibility, @
		globalAccount.on 'change', @model.updateInformation, @

		@model.updateInformation()


	onDispose: () =>
		@dropdownView.off null, null, @
		@model.off null, null, @
		globalAccount.off null, null, @

		@dropdownView.dispose()


	render: () =>
		@$el.html @html
		@$el.append @dropdownView.render().el

		@_fixName()
		@_fixVisibility()

		return @


	_fixName: () =>
		@$('.accountHeaderFirstName').html @model.get 'firstName'
		@$('.accountHeaderLastName').html @model.get 'lastName'


	_fixVisibility: () =>
		@$el.css 'display', if @model.get('visible') then 'inline-block' else 'none'


	_handleClick: (event) =>
		@model.dropdownModel.toggleVisibility()


	_handleDropdownSelection: (selectedName) =>
		switch selectedName
			when @model.PROFILE_DROPDOWN_OPTION.name
				window.location.href = '/account'
			when @model.LOGOUT_DROPDOWN_OPTION.name
				@_performLogoutRequest()
			else
				console.error 'Unhandled dropdown selection: ' + selectedName


	_performLogoutRequest: () =>
		console.log '>> need to make logout request'
		window.location.href = '/'

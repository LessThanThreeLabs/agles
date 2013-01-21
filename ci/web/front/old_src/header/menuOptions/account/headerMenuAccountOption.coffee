window.HeaderMenuAccountOption = {}


class HeaderMenuAccountOption.Model extends Backbone.Model
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
		attributesToSet = 
			firstName: globalAccount.get 'firstName'
			lastName: globalAccount.get 'lastName'
			visible: globalAccount.get 'loggedIn'
		@set attributesToSet, 
			error: (model, error) => console.error error


class HeaderMenuAccountOption.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenuAccountOption headerMenuOption'
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
		requestData =
			method: 'logout'
			args: {}
		socket.emit 'users:update', requestData, (error) =>
			if error?
				console.error error
			else
				window.location.href = '/'

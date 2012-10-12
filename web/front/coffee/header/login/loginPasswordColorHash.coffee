window.LoginPasswordColorHash = {}


class LoginPasswordColorHash.Model extends Backbone.Model
	defaults:
		password: ''
		hash: null

	initialize: () =>
		@on 'change:password', @_updateHashValue


	_updateHashValue: () =>
		if @get('password') is '' then @set 'hash', null
		else @set 'hash', CryptoJS.SHA256 @get('password')	


class LoginPasswordColorHash.View extends Backbone.View
	tagName: 'div'
	className: 'loginPasswordColorHash'
	template: Handlebars.compile '<div class="hashColor firstHashColor"></div>
		<div class="hashColor secondHashColor"></div>
		<div class="hashColor thirdHashColor"></div>
		<div class="hashColor fourthHashColor"></div>'

	initialize: () =>
		@model.on 'change:hash', @_updateHashColors


	render: () =>
		@$el.html @template()
		@_updateHashColors()
		return @


	_updateHashColors: () =>
		hash = @model.get 'hash'

		if hash? then @_setHashColors hash
		else @_resetHashColors()	


	_resetHashColors: () =>
		$('.firstHashColor').css 'background-color', '#FFFFFF'
		$('.secondHashColor').css 'background-color', '#FFFFFF'
		$('.thirdHashColor').css 'background-color', '#FFFFFF'
		$('.fourthHashColor').css 'background-color', '#FFFFFF'


	_setHashColors: (hash) =>
		$('.firstHashColor').css 'background-color', @_getColorFromInt hash.words[2]
		$('.secondHashColor').css 'background-color', @_getColorFromInt hash.words[4]
		$('.thirdHashColor').css 'background-color', @_getColorFromInt hash.words[5]
		$('.fourthHashColor').css 'background-color', @_getColorFromInt hash.words[7]


	_getColorFromInt: (value) =>
		hex = value.toString 16
		return '#' + hex.substr 1, 6
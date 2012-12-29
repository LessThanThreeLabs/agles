window.PrettyNotification = {}


class PrettyNotification.Model extends Backbone.Model
	ALLOWED_TYPES: ['information', 'success', 'warning', 'error']
	defaults:
		type: 'information'
		text: ''
		duration: 5000


	validate: (attributes) =>
		if attributes.type not in @ALLOWED_TYPES
			return new Error 'Invalid type: ' + attributes.type

		if typeof attributes.text isnt 'string'
			return new Error 'Invalid text value: ' + attributes.text

		if typeof attributes.duration isnt 'number' or attributes.duration < 0
			return new Error 'Invalid duration: ' + attributes.duration

		return


class PrettyNotification.View extends Backbone.View
	tagName: 'div'
	className: 'prettyNotification'
	html: '<div class="prettyNotificationContainer">
			<div class="notificationText">hello</div>
		</div>'
	events: 'click': '_handleClick'
	_destroyed: false


	initialize: () =>
		@model.on 'change:type', @_fixType
		@model.on 'change:text', @_fixTextField 


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @html
		@_fixType()
		@_fixTextField()

		if @model.get('duration') > 0
			setTimeout (() => @_destroy()), @model.get 'duration'

		return @


	_destroy: () =>
		return if @_destroyed
		@_destroyed = true

		@$el.addClass 'fadeOut'
		setTimeout (() => @dispose()), 800


	_fixType: () =>
		@$('.prettyNotificationContainer').removeClass().addClass 'prettyNotificationContainer'
		@$('.prettyNotificationContainer').addClass @model.get 'type'


	_fixTextField: () =>
		@$('.notificationText').html @model.get 'text'


	_handleClick: (event) =>
		@_destroy()

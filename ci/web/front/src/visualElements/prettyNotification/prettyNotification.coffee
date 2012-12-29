window.PrettyNotification = {}


class PrettyNotification.Model extends Backbone.Model
	ALLOWED_TYPES: ['information', 'success', 'warning', 'error']
	defaults:
		type: 'information'
		sticky: false
		text: ''


	validate: (attributes) =>
		if attributes.type not in @ALLOWED_TYPES
			return new Error 'Invalid type: ' + attributes.type

		if typeof attributes.sticky isnt 'boolean'
			return new Error 'Invalid sticky value: ' + attributes.sticky

		return


class PrettyNotification.View extends Backbone.View
	tagName: 'div'
	className: 'prettyNotification'
	html: '<div class="prettyNotificationContainer">
			<div class="notificationText">hello</div>
		</div>'
	events: 'click': '_handleClick'


	initialize: () =>
		@model.on 'change:type', @_fixType
		@model.on 'change:text', @_fixTextField 


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @html
		@_fixType()
		@_fixTextField()

		# setTimeout (() =>
		# 	@dispose()
		# 	), 4000

		return @


	_fixType: () =>
		@$('.prettyNotificationContainer').removeClass().addClass 'prettyNotificationContainer'
		@$('.prettyNotificationContainer').addClass @model.get 'type'


	_fixTextField: () =>
		@$('.notificationText').html @model.get 'text'


	_handleClick: (event) =>
		console.log 'clicked!!'

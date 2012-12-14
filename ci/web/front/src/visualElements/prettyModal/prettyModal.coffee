window.PrettyModal = {}


class PrettyModal.Model extends Backbone.Model
	defaults:
		visible: false


	toggleVisibility: () =>
		@set 'visible', not @get 'visible'


	validate: (attributes) =>
		if typeof attributes.visible isnt 'boolean'
			return new Error 'Invalid visibility ' + attributes.visibile

		return


class PrettyModal.View extends Backbone.View
	tagName: 'div'
	className: 'prettyModal'
	html: '<div class="prettyModalBackdrop"></div>
		<div class="prettyModalContent">hello</div>'


	initialize: () =>
		@model.on 'change:visible', @_fixVisibility, @

		setTimeout (() =>
			@model.set 'visible', true
			), 2000


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @html
		@_fixVisibility()
		return @


	_fixVisibility: () =>
		if @model.get 'visible'
			@$el.addClass 'visible'
			$('html').bind 'keydown', @_handleKeyPress
			@$('.prettyModalBackdrop').bind 'click', @_handleBackdropClick
		else
			$('html').unbind 'keydown', @_handleKeyPress
			@$('.prettyModalBackdrop').unbind 'click', @_handleBackdropClick
			@$el.removeClass 'visible'


	_handleBackdropClick: (event) =>
		@model.set 'visible', false


	_handleKeyPress: (event) =>
		# listen for escape key
		if event.keyCode is 27
			@model.set 'visible', false

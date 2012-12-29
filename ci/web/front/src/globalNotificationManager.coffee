class GlobalNotificationManager extends Backbone.View
	tagName: 'div'
	className: 'globalNotificationManager'
	html: ''


	render: () =>
		@$el.html @html
		return @


	addNotification: () =>
		console.log 'need to add notificaiton'

		prettyNotificationModel = new PrettyNotification.Model
			type: 'information'
			text: 'hello there!'
			sticky: false
		prettyNotificationView = new PrettyNotification.View model: prettyNotificationModel

		@$el.append prettyNotificationView.render().el


console.log 'here!'
window.globalNotificationManager = new GlobalNotificationManager()
$('body').prepend window.globalNotificationManager.render().el

setTimeout (() =>
	console.log 'adding notification...'
	globalNotificationManager.addNotification()
	), 500

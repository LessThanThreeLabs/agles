class GlobalNotificationManager extends Backbone.View
	tagName: 'div'
	className: 'globalNotificationManager'
	html: ''


	render: () =>
		@$el.html @html
		return @


	addNotification: (type, text, duration=5000) =>
		console.log 'need to add notificaiton'

		prettyNotificationModel = new PrettyNotification.Model
			type: type
			text: text
			duration: duration
		prettyNotificationView = new PrettyNotification.View model: prettyNotificationModel

		@$el.append prettyNotificationView.render().el


console.log 'here!'
window.globalNotificationManager = new GlobalNotificationManager()
$('body').prepend window.globalNotificationManager.render().el

setTimeout (() => globalNotificationManager.addNotification('information', 'hello 1', 0)), 500
setTimeout (() => globalNotificationManager.addNotification('success', 'hello 2', 0)), 1000
setTimeout (() => globalNotificationManager.addNotification('warning', 'hello 3', 0)), 1500
setTimeout (() => globalNotificationManager.addNotification('error', 'hello 4', 0)), 2000

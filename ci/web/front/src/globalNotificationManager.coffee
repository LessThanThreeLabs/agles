class GlobalNotificationManager extends Backbone.View
	tagName: 'div'
	className: 'globalNotificationManager'
	html: ''


	render: () =>
		@$el.html @html
		return @


	addNotification: (type, text, duration=5000) =>
		prettyNotificationModel = new PrettyNotification.Model
			type: type
			text: text
			duration: duration
		prettyNotificationView = new PrettyNotification.View model: prettyNotificationModel

		@$el.append prettyNotificationView.render().el


window.globalNotificationManager = new GlobalNotificationManager()
$('body').prepend window.globalNotificationManager.render().el

setTimeout (() => globalNotificationManager.addNotification('information', 'Check this out.  I can display notifications.  So cool!', 5000)), 500

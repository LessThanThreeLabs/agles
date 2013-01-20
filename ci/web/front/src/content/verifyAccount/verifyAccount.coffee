window.VerifyAccount = {}


class VerifyAccount.Model extends Backbone.Model
	

class VerifyAccount.View extends Backbone.View
	tagName: 'div'
	className: 'verifyAccount'
	template: Handlebars.compile '<div class="verifyAccountContent">
			<div class="congratulationsMessage">
				Congratulations {{firstName}} {{lastName}}, your account is now active!
			</div>
			<div><img class="congratulationsImage" src="/img/awesomeFace' + filesSuffix + '.png"></div>
		</div>'


	render: () =>
		@$el.html @template
			firstName: globalAccount.get 'firstName'
			lastName: globalAccount.get 'lastName'
		return @

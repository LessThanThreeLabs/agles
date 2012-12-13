class GlobalAccount extends Backbone.Model
	defaults:
		email: null
		firstName: null
		lastName: null


	validate: (attributes) =>
		if not attributes.email? or attributes.email is ''
			return new Error 'Invaild email: ' + attributes.email

		if not attributes.firstName? or attributes.firstName is ''
			return new Error 'Invalid first name: ' + attributes.firstName
			
		if not attributes.lastName? or attributes.lastName is ''
			return new Error 'Invalid last name: ' + attributes.lastName

		return


window.globalAccount = new GlobalAccount()

if window.accountInformation?
	window.globalAccount.set
		email: window.accountInformation.email
		firstName: window.accountInformation.firstName
		lastName: window.accountInformation.lastName

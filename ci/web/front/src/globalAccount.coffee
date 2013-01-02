class GlobalAccount extends Backbone.Model
	defaults:
		userId: null
		email: null
		firstName: null
		lastName: null
		loggedIn: false


	initialize: () =>
		@on 'change:email', () =>
			attributesToSet = loggedIn: @get('email') isnt ''
			@set attributesToSet, error: (model, error) => console.error error


	validate: (attributes) =>
		if typeof attributes.userId isnt 'number' or attributes.userId < 0
			return new Error 'Invalid user id (make sure it is not a string): ' + attributes.userId

		if typeof attributes.email isnt 'string'
			return new Error 'Invaild email: ' + attributes.email

		if typeof attributes.firstName isnt 'string'
			return new Error 'Invalid first name: ' + attributes.firstName
			
		if typeof attributes.lastName isnt 'string'
			return new Error 'Invalid last name: ' + attributes.lastName

		if typeof attributes.loggedIn isnt 'boolean'
			return new Error 'Invalid logged in state: ' + attributes.loggedIn

		return


window.globalAccount = new GlobalAccount()

if window.accountInformation?
	console.error 'NEED TO BE USING THE CORRECT USER ID HERE!!'
	attributesToSet =
		userId: 1000
		email: window.accountInformation.email
		firstName: window.accountInformation.firstName
		lastName: window.accountInformation.lastName
	window.globalAccount.set attributesToSet, 
		error: (model, error) => console.error error

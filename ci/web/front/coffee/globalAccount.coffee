class GlobalAccount extends Backbone.Model
	defaults:
		email: null
		firstName: null
		lastName: null


	validate: (attributes) =>
		if not attributes.email?
			return new Error 'Invaild email: ' + attributes.email

		if not attributes.firstName?
			return new Error 'Invalid first name: ' + attributes.firstName
			
		if not attributes.lastName?
			return new Error 'Invalid last name: ' + attributes.lastName

		return


window.globalAccount = new GlobalAccount()
	
socket.on 'accountUpdate', (data) ->
	window.globalAccount.set data,
		error: (model, error) => console.error error

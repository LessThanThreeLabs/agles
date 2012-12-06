class GlobalAccount extends Backbone.Model
	defaults:
		firstName: null
		lastName: null


	validate: (attributes) =>
		if attributes.firstName is null
			return new Error 'Invalid first name'
		if attributes.lastName is null
			return new Error 'Invalid last name'

		return


window.globalAccount = new GlobalAccount()
	
socket.on 'accountUpdate', (data) ->
	window.globalAccount.set data,
		error: (model, error) => console.error error

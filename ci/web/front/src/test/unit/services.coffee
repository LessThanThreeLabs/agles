'use strict'

describe 'Koality services', () ->

	describe 'initial state', () ->

		it 'should have non-null values', () ->
			fileSuffix = '_d487ab5e'; csrfToken = '4ed9a4a31had'; userId = 17
			email ='email@address.com'; firstName = 'First'; lastName = 'Last'

			module 'koality.service', ($provide) ->
				mockedWindow = 
					fileSuffix: fileSuffix
					csrfToken: csrfToken
					accountInformation:
						userId: 17
						email: email
						firstName: firstName
						lastName: lastName
				$provide.value '$window', mockedWindow
				return

			inject (initialState) ->
				expect(initialState.fileSuffix).toBe fileSuffix
				expect(initialState.csrfToken).toBe csrfToken
				expect(initialState.user.id).toBe 17
				expect(initialState.user.email).toBe email
				expect(initialState.user.firstName).toBe firstName
				expect(initialState.user.lastName).toBe lastName

		it 'should have null values', () ->
			module 'koality.service', ($provide) ->
				mockedWindow = 
					fileSuffix: ''
					csrfToken: ''
					accountInformation:
						userId: 'bad_user_id'
						email: ''
						firstName: ''
						lastName: ''
				$provide.value '$window', mockedWindow
				return

			inject (initialState) ->
				expect(initialState.fileSuffix).toBeNull()
				expect(initialState.csrfToken).toBeNull()
				expect(initialState.user.id).toBeNull()
				expect(initialState.user.email).toBeNull()
				expect(initialState.user.firstName).toBeNull()
				expect(initialState.user.lastName).toBeNull()

		it 'should not allow edits', () ->
			module 'koality.service'

			inject (initialState) ->
				addValueToInitialState = () ->
					initialState.blah = 'blah'

				removeValueFromInitialState = () ->
					delete initialState.user

				expect(addValueToInitialState).toThrow()
				expect(removeValueFromInitialState).toThrow()

	describe 'account information', () ->
		id = 17
		email = 'email@address.com'
		firstName = 'First'
		lastName = 'Last'

		it 'should have correct values', () ->
			module 'koality.service', ($provide) ->
				mockedInitialState =
					user:
						id: id
						email: email
						firstName: firstName
						lastName: lastName
				$provide.value 'initialState', mockedInitialState
				return

			inject (accountInformation) ->
				expect(accountInformation.id).toBe id
				expect(accountInformation.email).toBe email
				expect(accountInformation.firstName).toBe firstName
				expect(accountInformation.lastName).toBe lastName

	describe 'file suffix adder', () ->
		fileSuffix = '_hc8oeb1f'
		
		beforeEach () ->
			module 'koality.service', ($provide) ->
				mockedInitialState = fileSuffix: fileSuffix
				$provide.value 'initialState', mockedInitialState
				return
			
		it 'should properly add the correct file suffix for valid file urls', () ->
			inject (fileSuffixAdder) ->
				expect(fileSuffixAdder.addFileSuffix('a.gif')).toBe "a#{fileSuffix}.gif"
				expect(fileSuffixAdder.addFileSuffix('/img/a.png')).toBe "/img/a#{fileSuffix}.png"
				expect(fileSuffixAdder.addFileSuffix('/short.html')).toBe "/short#{fileSuffix}.html"
				expect(fileSuffixAdder.addFileSuffix('/img/longerName.fakeExtension')).toBe "/img/longerName#{fileSuffix}.fakeExtension"

		it 'should fail to add the correct file suffix for invalid file urls', () ->
			inject (fileSuffixAdder) ->
				expect(fileSuffixAdder.addFileSuffix('agif')).toBe 'agif'
				expect(fileSuffixAdder.addFileSuffix('/img/apng')).toBe '/img/apng'
				expect(fileSuffixAdder.addFileSuffix('/shorthtml')).toBe '/shorthtml'
				expect(fileSuffixAdder.addFileSuffix('/img/longerNamefakeExtension')).toBe '/img/longerNamefakeExtension'

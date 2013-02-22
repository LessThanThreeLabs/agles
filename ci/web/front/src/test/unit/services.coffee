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
						id: userId
						email: email
						firstName: firstName
						lastName: lastName
				$provide.value '$window', mockedWindow
				return

			inject (initialState) ->
				expect(initialState.fileSuffix).toBe fileSuffix
				expect(initialState.csrfToken).toBe csrfToken
				expect(initialState.user.id).toBe userId
				expect(initialState.user.email).toBe email
				expect(initialState.user.firstName).toBe firstName
				expect(initialState.user.lastName).toBe lastName

		it 'should have null values', () ->
			module 'koality.service', ($provide) ->
				mockedWindow = 
					fileSuffix: ''
					csrfToken: ''
					accountInformation:
						id: ''
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

	describe 'integer converter', () ->
		beforeEach module 'koality.service'

		it 'should return numbers given valid strings', () ->
			inject (integerConverter) ->
				expect(typeof integerConverter.toInteger('5')).toBe 'number'
			
		it 'should properly parse valid integers', () ->
			inject (integerConverter) ->
				expect(integerConverter.toInteger '5').toBe 5
				expect(integerConverter.toInteger '-1').toBe -1
				expect(integerConverter.toInteger '123456789').toBe 123456789

		it 'should return null for invalid integers', () ->
			inject (integerConverter) ->
				expect(integerConverter.toInteger '').toBeNull()
				expect(integerConverter.toInteger null).toBeNull()
				expect(integerConverter.toInteger undefined).toBeNull()
				expect(integerConverter.toInteger '1.3').toBeNull()
				expect(integerConverter.toInteger 'five').toBeNull()

	describe 'rpc', () ->
		mockedSocket = null

		beforeEach () ->
			jasmine.Clock.useMock()

			mockedSocket =
				makeRequest: jasmine.createSpy('makeRequest').andCallFake (resource, requestType, methodName, data, callback) ->
					setTimeout (() -> if callback? then callback null, 'ok'), 100

			module 'koality.service', ($provide) ->
				$provide.value 'socket', mockedSocket
				return
			
		it 'should properly call socket when making rpc requests', () ->
			inject (rpc) ->
				rpc.makeRequest 'users', 'update', 'login', id: 9001
				expect(mockedSocket.makeRequest).toHaveBeenCalled()
				expect(mockedSocket.makeRequest.callCount).toBe 1

				rpc.makeRequest 'users', 'update', 'logout', id: 9001
				expect(mockedSocket.makeRequest).toHaveBeenCalled()
				expect(mockedSocket.makeRequest.callCount).toBe 2

		it 'should have callback called after some delay', () ->
			inject (rpc) ->
				fakeCallback = jasmine.createSpy 'fakeCallback'

				rpc.makeRequest 'users', 'update', 'login', id: 9001, fakeCallback
				expect(mockedSocket.makeRequest).toHaveBeenCalled()
				expect(mockedSocket.makeRequest.callCount).toBe 1
				expect(fakeCallback).not.toHaveBeenCalled()
				jasmine.Clock.tick 101
				expect(fakeCallback).toHaveBeenCalled()

	describe 'events', () ->
		it 'should request to listen on eventName given from the socket', () ->
			eventToFireOn = 'aeoutnhuaensuha'
			mockedSocket =
				makeRequest: jasmine.createSpy('makeRequest').andCallFake (resource, requestType, methodName, data, callback) ->
					callback null, eventToFireOn
				respondTo: jasmine.createSpy('respondTo')

			module 'koality.service', ($provide) ->
				$provide.value 'socket', mockedSocket
				return

			inject (events) ->
				fakeCallback = () ->
				events.listen('users', 'basic information', 9001).setCallback(fakeCallback).subscribe()

				expect(mockedSocket.respondTo.mostRecentCall.args[0]).toBe eventToFireOn
				expect(mockedSocket.makeRequest.callCount).toBe 1
				expect(mockedSocket.respondTo.callCount).toBe 1

		it 'should handle subscribe and unsubscribe', () ->
			jasmine.Clock.useMock()

			interval = null
			eventToFireOn = 'aeoutnhuaensuha'
			mockedSocket =
				makeRequest: jasmine.createSpy('makeRequest').andCallFake (resource, requestType, methodName, data, callback) ->
					if requestType is 'subscribe' then callback null, eventToFireOn
					if requestType is 'unsubscribe' then clearInterval interval
				respondTo: jasmine.createSpy('respondTo').andCallFake (eventName, callback) ->
					assert.ok eventName is eventToFireOn
					interval = setInterval (() -> callback 'hello'), 100

			module 'koality.service', ($provide) ->
				$provide.value 'socket', mockedSocket
				return

			inject (events) ->
				fakeCallback = jasmine.createSpy 'fakeCallback'
				fakeEvents = events.listen('users', 'basic information', 9001).setCallback(fakeCallback).subscribe()

				expect(fakeCallback.callCount).toBe 0
				jasmine.Clock.tick 101
				expect(fakeCallback.callCount).toBe 1
				jasmine.Clock.tick 100
				expect(fakeCallback.callCount).toBe 2

				fakeEvents.unsubscribe()
				jasmine.Clock.tick 500
				expect(fakeCallback.callCount).toBe 2	

	describe 'changes rpc', () ->
		beforeEach () ->
			numChanges = 107
			mockedRpc =
				makeRequest: (resource, requestType, methodName, data, callback) ->
					endIndex = Math.min numChanges, data.startIndex + 100
					callback null, (num for num in [data.startIndex...endIndex])

			module 'koality.service', ($provide) ->
				$provide.value 'rpc', mockedRpc
				return
			
		it 'should receive changes', () ->
			inject (changesRpc) ->
				fakeCallback = jasmine.createSpy 'fakeCallback'

				changesRpc.queueRequest 17, 'all', [], 0, fakeCallback
				expect(fakeCallback.callCount).toBe 1
				expect(fakeCallback.mostRecentCall.args[1].length).toBe 100


		it 'should stop receiving changes if no more to receive', () ->
			inject (changesRpc) ->
				fakeCallback = jasmine.createSpy 'fakeCallback'

				changesRpc.queueRequest 17, 'all', [], 0, fakeCallback
				expect(fakeCallback.callCount).toBe 1
				expect(fakeCallback.mostRecentCall.args[1].length).toBe 100

				changesRpc.queueRequest 17, 'all', [], 100, fakeCallback
				expect(fakeCallback.callCount).toBe 2
				expect(fakeCallback.mostRecentCall.args[1].length).toBe 7

				changesRpc.queueRequest 17, 'all', [], 107, fakeCallback
				expect(fakeCallback.callCount).toBe 2

				changesRpc.queueRequest 17, 'all', [], 0, fakeCallback
				expect(fakeCallback.callCount).toBe 3
				expect(fakeCallback.mostRecentCall.args[1].length).toBe 100

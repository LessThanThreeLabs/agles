describe 'Koality services', () ->

	describe 'initial state', () ->

		it 'should have non-null values', () ->
			module 'koality.service', ($provide) ->
				mockedWindow = 
					fileSuffix: '_d487ab5e'
					csrfToken: '4ed9a4a31had'
					accountInformation:
						userId: 17
						email: 'email@address.com'
						firstName: 'First'
						lastName: 'Last'
				$provide.value '$window', mockedWindow
				return

			inject (initialState) ->
				expect(initialState.fileSuffix).toBe '_d487ab5e'
				expect(initialState.csrfToken).toBe '4ed9a4a31had'
				expect(initialState.user.id).toBe 17
				expect(initialState.user.email).toBe 'email@address.com'
				expect(initialState.user.firstName).toBe 'First'
				expect(initialState.user.lastName).toBe 'Last'

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


	describe 'file suffix adder', () ->
		beforeEach () ->
			module 'koality.service', ($provide) ->
				mockedWindow = fileSuffix: '_hc8oeb1f'
				$provide.value '$window', mockedWindow
				return
			
		it 'should properly add the correct file suffix for valid file urls', () ->
			inject (fileSuffixAdder) ->
				expect(fileSuffixAdder.addFileSuffix('a.gif')).toBe 'a_hc8oeb1f.gif'
				expect(fileSuffixAdder.addFileSuffix('/img/a.png')).toBe '/img/a_hc8oeb1f.png'
				expect(fileSuffixAdder.addFileSuffix('/short.html')).toBe '/short_hc8oeb1f.html'
				expect(fileSuffixAdder.addFileSuffix('/img/longerName.fakeExtension')).toBe '/img/longerName_hc8oeb1f.fakeExtension'

		it 'should fail to add the correct file suffix for invalid file urls', () ->
			inject (fileSuffixAdder) ->
				expect(fileSuffixAdder.addFileSuffix('agif')).toBe 'agif'
				expect(fileSuffixAdder.addFileSuffix('/img/apng')).toBe '/img/apng'
				expect(fileSuffixAdder.addFileSuffix('/shorthtml')).toBe '/shorthtml'
				expect(fileSuffixAdder.addFileSuffix('/img/longerNamefakeExtension')).toBe '/img/longerNamefakeExtension'

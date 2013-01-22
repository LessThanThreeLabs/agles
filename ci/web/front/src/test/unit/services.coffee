describe 'Koality services', () ->

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

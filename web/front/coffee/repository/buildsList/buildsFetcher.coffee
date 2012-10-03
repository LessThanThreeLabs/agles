window.BuildsFetcher = class BuildsFetcher
	@fetchingBuilds = false

	fetchBuilds: (repositoryId, type, start, end, callback) =>
		return false if @fetchingBuilds
		@fetchingBuilds = true

		requestData = 
			repositoryId: repositoryId
			type: type
			range:
				start: start
				end: end

		socket.emit 'builds:read', requestData, (error, buildsData) =>
			@fetchingBuilds = false
			callback error, buildsData

		return true

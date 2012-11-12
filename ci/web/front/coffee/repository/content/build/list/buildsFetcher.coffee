window.BuildsFetcher = class BuildsFetcher
	currentQuery: null
	currentCallback: null

	nextQuery: null
	nextCallback: null


	runQuery: (query, queuePolicy, callback) =>
		assert.ok query? and queuePolicy? and callback?

		if not @currentQuery?
			@currentQuery = query
			@currentCallback = callback
			@_fetchBuilds()
			return true
		else if queuePolicy is BuildsFetcher.QueuePolicy.QUEUE_IF_BUSY
			console.log 'queued'
			@nextQuery = query
			@nextCallback = callback
			return true

		return false


	_fetchBuilds: () =>
		console.log 'fetchBuilds called!'
		assert.ok @currentQuery? and @currentCallback?

		# requestData = 
		# 	method: 'range'
		# 	args:
		# 		repositoryId: @currentQuery.repositoryId
		# 		type: @currentQuery.type
		# 		queryString: @currentQuery.queryString
		# 		range:
		# 			start: @currentQuery.start
		# 			end: @currentQuery.end

		# socket.emit 'builds:read', requestData, (error, buildsData) =>
		# 	callback = @currentCallback
		# 	@_runNextQuery()
		# 	callback error, buildsData

		console.log 'creating and returning fake builds'
		buildsData = createFakeBuilds @currentQuery.repositoryId, @currentQuery.start, @currentQuery.end
		result =
			type: @currentQuery.type
			queryString: @currentQuery.queryString
			builds: buildsData

		callback = @currentCallback
		@_runNextQuery()
		callback null, result
		console.log 'returned stuff'

		return true


	_runNextQuery: () =>
		@currentQuery = @nextQuery
		@currentCallback = @nextCallback
		@nextQuery = null
		@nextCallback = null

		@_fetchBuilds() if @currentQuery?


window.BuildsFetcher.QueuePolicy =
	QUEUE_IF_BUSY: 'queueIfBusy'
	DO_NOT_QUEUE: 'doNotQueue'






createFakeBuilds = (repositoryId, start, end) ->
	numberOffset = Math.floor Math.random() * 10000
	fakeBuilds = (createFakeBuild repositoryId, number, numberOffset for number in [start...end])
	return fakeBuilds


createFakeBuild = (repositoryId, number, numberOffset) ->
	fakeBuild =
		id: Math.floor Math.random() * 100000
		repositoryId: repositoryId
		number: number + numberOffset
		status: getRandomStatus()
		startTime: 'second breakfast'
		endTime: 'pumping in da club'


getRandomStatus = () ->
	return if Math.random() > .35 then 'success' else 'failed'

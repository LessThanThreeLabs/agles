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
			@nextQuery = query
			@nextCallback = callback
			return true

		return false


	_fetchBuilds: () =>
		console.log 'fetchBuilds called!'
		assert.ok @currentQuery? and @currentCallback?

		requestData = 
			repositoryId: @currentQuery.repositoryId
			type: @currentQuery.type
			queryString: @currentQuery.queryString
			range:
				start: @currentQuery.start
				end: @currentQuery.end

		socket.emit 'builds:read', requestData, (error, buildsData) =>
			callback = @currentCallback
			@_runNextQuery()
			callback error, buildsData

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

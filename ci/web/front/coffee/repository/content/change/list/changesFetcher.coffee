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
		assert.ok @currentQuery? and @currentQuery.repositoryId? and @currentQuery.queryString?
		assert.ok @currentCallback?
		
		requestData = 
			method: 'range'
			args:
		 		repositoryId: @currentQuery.repositoryId
		 		queryString: @currentQuery.queryString
		 		start: @currentQuery.startNumber
		 		numResults: @currentQuery.numberToRetrieve

		socket.emit 'builds:read', requestData, (error, buildsData) =>
			if error?
				callback = @currentCallback
				@_runNextQuery()
				callback error
			else
				result = 
					queryString: @currentQuery.queryString
					builds: buildsData
				callback = @currentCallback
				@_runNextQuery()
				callback null, result


	_runNextQuery: () =>
		@currentQuery = @nextQuery
		@currentCallback = @nextCallback
		@nextQuery = null
		@nextCallback = null

		@_fetchBuilds() if @currentQuery?


BuildsFetcher.QueuePolicy =
	QUEUE_IF_BUSY: 'queueIfBusy'
	DO_NOT_QUEUE: 'doNotQueue'

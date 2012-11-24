window.BuildsFetcher = class BuildsFetcher
	currentQuery: null
	currentCallback: null

	nextQuery: null
	nextCallback: null


	runQuery: (query, queuePolicy, callback) =>
		assert.ok query? and queuePolicy? and callback?
		console.log query
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
		assert.ok @currentQuery? and @currentQuery.repositoryId? and @currentQuery.queryString?
		assert.ok @currentCallback?
		
		requestData = 
			method: 'range'
			args:
		 		repositoryId: @currentQuery.repositoryId
		 		type: @currentQuery.type
		 		queryString: @currentQuery.queryString
		 		start: @currentQuery.start
		 		numResults: @currentQuery.end - @currentQuery.start

		socket.emit 'builds:read', requestData, (error, buildsData) =>
			if error?
				callback = @currentCallback
				@_runNextQuery()
				callback error
			else
				result = 
					type: @currentQuery.type
					queryString: @currentQuery.queryString
					builds: buildsData
				callback = @currentCallback
				@_runNextQuery()
				console.log result
				callback null, result
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

window.ChangesFetcher = class ChangesFetcher
	currentQuery: null
	currentCallback: null

	nextQuery: null
	nextCallback: null


	runQuery: (query, queuePolicy, callback) =>
		assert.ok query? and queuePolicy? and callback?
		if not @currentQuery?
			@currentQuery = query
			@currentCallback = callback
			@_fetchChanges()
			return true
		else if queuePolicy is ChangesFetcher.QueuePolicy.QUEUE_IF_BUSY
			@nextQuery = query
			@nextCallback = callback
			return true

		return false


	_fetchChanges: () =>
		assert.ok @currentQuery? and @currentQuery.repositoryId? and @currentQuery.queryString?
		assert.ok @currentCallback?
		
		requestData = 
			method: 'range'
			args:
		 		repositoryId: @currentQuery.repositoryId
		 		queryString: @currentQuery.queryString
		 		start: @currentQuery.startNumber
		 		numResults: @currentQuery.numberToRetrieve

		socket.emit 'changes:read', requestData, (error, changeData) =>
			if error?
				callback = @currentCallback
				@_runNextQuery()
				callback error
			else
				result = 
					queryString: @currentQuery.queryString
					changes: changeData
				callback = @currentCallback
				@_runNextQuery()
				callback null, result


	_runNextQuery: () =>
		@currentQuery = @nextQuery
		@currentCallback = @nextCallback
		@nextQuery = null
		@nextCallback = null

		@_fetchChanges() if @currentQuery?


ChangesFetcher.QueuePolicy =
	QUEUE_IF_BUSY: 'queueIfBusy'
	DO_NOT_QUEUE: 'doNotQueue'

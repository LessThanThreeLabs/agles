window.ChangeMetadata = {}


class ChangeMetadata.Model extends Backbone.Model
	defaults:
		committerEmail: null
		committerFirstName: null
		committerLastName: null
		commitMessage: null
		commitTime: null
		startTime: null
		endTime: null


	initialize: () =>


	fetchMetadata: () =>
		requestData =
			method: 'getChangeMetadata'
			args: id: globalRouterModel.get('changeId')

		socket.emit 'changes:read', requestData, (error, changeMetadata) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error error
			else
				attributesToSet =
					committerEmail: changeMetadata.user.email
					committerFirstName: changeMetadata.user.firstName
					committerLastName: changeMetadata.user.lastName
					commitMessage: changeMetadata.commit.message
					commitTime: changeMetadata.commit.timestamp
					commitSha: changeMetadata.commit.sha
					startTime: changeMetadata.change.startTime
					endTime: changeMetadata.change.endTime
				@set attributesToSet,
					error: (model, error) => console.error error


	validate: (attributes) =>
		if typeof attributes.committerEmail isnt 'string' or attributes.committerEmail is ''
			return new Error 'Invalid committer email: ' + attributes.committerEmail

		if typeof attributes.committerFirstName isnt 'string' or attributes.committerFirstName is ''
			return new Error 'Invalid committer first name: ' + attributes.committerFirstName

		if typeof attributes.committerLastName isnt 'string' or attributes.committerLastName is ''
			return new Error 'Invalid committer last name: ' + attributes.committerLastName

		if typeof attributes.commitMessage isnt 'string'
			return new Error 'Invalid commitMessage: ' + attributes.commitMessage

		if typeof attributes.commitTime isnt 'number' or (new Date attributes.commitTime) is 'Invalid Date'
			return new Error 'Invalid commit time: ' + attributes.commitTime

		if attributes.startTime? and (typeof attributes.startTime isnt 'number' or (new Date attributes.startTime) is 'Invalid Date')
			return new Error 'Invalid start time: ' + attributes.startTime

		if attributes.endTime? and (typeof attributes.endTime isnt 'number' or (new Date attributes.endTime) is 'Invalid Date')
			return new Error 'Invalid end time: ' + attributes.endTime

		return


class ChangeMetadata.View extends Backbone.View
	tagName: 'div'
	className: 'changeMetadata'
	template: Handlebars.compile '<div class="changeMetadataContainer">
			<!--
			<div class="changeTimeInterval">
				<span class="changeStartTime">{{startTime}}</span>
				<span class="changeTimeDivider"> to </span>
				<span class="changeEndTime">{{endTime}}</span>
			</div>
			-->

			<div class="prettyForm">
				<div class="prettyFormRow">
					<div class="prettyFormLabel committerLabel">Committer</div>
					<div class="prettyFormValue committerValue">
						{{committerFirstName}} {{committerLastName}}
						<br> {{committerEmail}}
					</div>
				</div>
				<div class="prettyFormRow">
					<div class="prettyFormLabel commitTimeLabel">Commit time</div>
					<div class="prettyFormValue commitTimeValue">{{commitTime}}</div>
				</div>
				<div class="prettyFormRow">
					<div class="prettyFormLabel commitShaLabel">Commit sha</div>
					<div class="prettyFormValue commitShaValue">{{commitSha}}</div>
				</div>
				<div class="prettyFormRow">
					<div class="prettyFormLabel commitMessageLabel">Commit message</div>
					<div class="prettyFormValue commitMessageValue">{{commitMessage}}</div>
				</div>
			</div>
		</div>'


	initialize: () =>
		@model.on 'change', @render, @
		@model.fetchMetadata()


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		startTime = if not @model.get('startTime')? then '??' else
			$.format.date new Date(@model.get('startTime')), 'MM/dd hh:mm:ss a'
		endTime = if not @model.get('endTime')? then '??' else
			$.format.date new Date(@model.get('endTime')), 'hh:mm:ss a'
		commitTime = if not @model.get('commitTime') then '??' else
			$.format.date new Date(@model.get('commitTime')), 'ddd MM/dd hh:mm:ss a'

		@$el.html @template
			committerEmail: @model.get 'committerEmail'
			committerFirstName: @model.get 'committerFirstName'
			committerLastName: @model.get 'committerLastName'
			commitSha: @model.get 'commitSha'
			commitMessage: @model.get 'commitMessage'
			commitTime: commitTime
			startTime: startTime
			endTime: endTime
		return @

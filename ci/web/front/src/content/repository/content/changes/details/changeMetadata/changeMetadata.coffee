window.ChangeMetadata = {}


class ChangeMetadata.Model extends Backbone.Model
	defaults:
		submitterEmail: ''
		submitterFirstName: ''
		submitterLastName: ''
		commitMessage: ''
		commitTime: 0
		startTime: 0
		endTime: 0


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
					submitterEmail: changeMetadata.user.email
					submitterFirstName: changeMetadata.user.firstName
					submitterLastName: changeMetadata.user.lastName
					commitMessage: changeMetadata.commit.message
					commitTime: changeMetadata.commit.timestamp
					startTime: changeMetadata.change.startTime
					endTime: changeMetadata.change.endTime
				@set attributesToSet,
					error: (model, error) => console.error error


	validate: (attributes) =>
		if typeof attributes.submitterEmail isnt 'string' or attributes.submitterEmail is ''
			return new Error 'Invalid submitter email: ' + attributes.submitterEmail

		if typeof attributes.submitterFirstName isnt 'string' or attributes.submitterFirstName is ''
			return new Error 'Invalid submitter first name: ' + attributes.submitterFirstName

		if typeof attributes.submitterLastName isnt 'string' or attributes.submitterLastName is ''
			return new Error 'Invalid submitter last name: ' + attributes.submitterLastName

		if typeof attributes.commitMessage isnt 'string'
			return new Error 'Invalid commitMessage: ' + attributes.commitMessage

		if typeof attributes.commitTime isnt 'number' or (new Date attributes.commitTime) is 'Invalid Date'
			return new Error 'Invalid commit time: ' + attributes.commitTime

		if typeof attributes.startTime isnt 'number' or (new Date attributes.startTime) is 'Invalid Date'
			return new Error 'Invalid start time: ' + attributes.startTime

		if typeof attributes.endTime isnt 'number' or (new Date attributes.endTime) is 'Invalid Date'
			return new Error 'Invalid end time: ' + attributes.endTime

		return


class ChangeMetadata.View extends Backbone.View
	tagName: 'div'
	className: 'changeMetadata'
	template: Handlebars.compile '<div class="changeMetadataContainer">
			<div class="changeTimeInterval">{{startTime}} to {{endTime}}</div>
			<div class="changeSubmitter">
				Submitted by: 
				<span class="changeSubmitterName">{{submitterFirstName}} {{submitterLastName}}</span>
				<span class="changeSubmitterEmail">{{submitterEmail}}</span>
			</div>
			<div class="changeCommitTime">Commit time: {{commitTime}}<div>
			<div class="changeCommitMessage">{{commitMessage}}</div>
		</div>'


	initialize: () =>
		@model.on 'change', @render, @
		@model.fetchMetadata()


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @template
			submitterEmail: @model.get 'submitterEmail'
			submitterFirstName: @model.get 'submitterFirstName'
			submitterLastName: @model.get 'submitterLastName'
			commitMessage: @model.get 'commitMessage'
			commitTime: new Date @model.get 'commitTime'
			startTime: new Date @model.get 'startTime'
			endTime: new Date @model.get 'endTime'
		return @

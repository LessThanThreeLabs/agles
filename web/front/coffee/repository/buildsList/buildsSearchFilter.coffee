window.BuildsSearchFilter = {}


class BuildsSearchFilter.Model extends Backbone.Model
	defaults:
		query: ''

	initialize: () =>
		


class BuildsSearchFilter.View extends Backbone.View
	tagName: 'div'
	className: 'btn filterButton'
	template: Handlebars.compile '<img src="/img/icons/critical.svg" class="selectedSearchImage" />'

	popoverTemplate: Handlebars.compile '<div class="searchFilter">
			{{#each filters}}
			<label class="radio searchFilterOption">
				<input type="radio" name="searchFilterRadio">
				<img src={{{imageSource}}} class="searchImage" />
				<span class="filterDescription">
					{{{type}}<br><small class="muted">{{{description}}</small>
				</span>
			</label>
			{{/each}}
		</div>'


	initialize: () =>


	render: () =>
		@$el.html @template()
		setTimeout (() => @_setupPopover()), 100
		return @


	_setupPopover: () =>
		@$el.popover
			title: 'Filter by Type'
			content: @popoverTemplate 
				filters: [
					{ imageSource: 'img/icons/everyone.svg'
					type: 'Everyone'
					description: 'View builds created by eveyone,<br>including you.' },
					{ imageSource: 'img/icons/user.svg'
					type: 'User'
					description: 'View your builds and code <br> reviews assigned to you.' },
					{ imageSource: 'img/icons/critical.svg'
					type: 'Critical'
					description: 'View builds that need attention.' }
				]
window.BuildsSearchFilterSelector = {}


class BuildsSearchFilterSelector.Model extends Backbone.Model
	defaults:
		query: ''

	initialize: () =>
		


class BuildsSearchFilterSelector.View extends Backbone.View
	tagName: 'div'
	className: 'searchFilter'
	template: Handlebars.compile '{{#each filters}}
			<label class="radio searchFilterOption">
				<input type="radio" name="searchFilterRadioGroup" class="searchFilterRadio" value={{value}}>
				<img src={{{imageSource}}} class="searchImage" />
				<span class="filterDescription">
					{{{type}}<br><small class="muted">{{{description}}</small>
				</span>
			</label>
			{{/each}}'

	initialize: () =>
		$('.searchFilterRadio').live 'change', @_handleRadioSelection
		

	render: () =>
		@$el.html @template 
			filters: [
				{ value: 'everyone'
				imageSource: 'img/icons/everyone.svg'
				type: 'Everyone'
				description: 'View builds created by eveyone,<br>including you.' },
				{ value: 'user'
				imageSource: 'img/icons/user.svg'
				type: 'User'
				description: 'View your builds and code <br> reviews assigned to you.' },
				{ value: 'critical'
				imageSource: 'img/icons/critical.svg'
				type: 'Critical'
				description: 'View builds that need attention.' }
			]
		return @


	_handleRadioSelection: (event) ->
		console.log event.target.value
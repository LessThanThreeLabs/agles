window.BuildsSearchFilterSelector = {}


class BuildsSearchFilterSelector.Model extends Backbone.Model
	types: [
		new BuildsSearchFilterType 'everyone', 'Everyone', 'View builds created by eveyone,<br>including you.', '/img/icons/everyone.svg'
		new BuildsSearchFilterType 'user', 'User', 'View your builds and code <br> reviews assigned to you.', '/img/icons/user.svg'
		new BuildsSearchFilterType 'important', 'Important', 'View builds that need attention.', '/img/icons/critical.svg'
	]


	initialize: () =>
		@set 'selectedType', @types[2], silent: true


	validate: (attributes) =>
		if @types.indexOf(attributes.selectedType) is -1
			return new Error 'Bad selected filter type.'

		return


	getFilterTypeFromName: (name) =>
		for type in @types
			return type if name is type.name
		return null


class BuildsSearchFilterSelector.View extends Backbone.View
	tagName: 'div'
	className: 'searchFilter'
	template: Handlebars.compile '{{#each filters}}
			<label class="radio searchFilterOption">
				<input type="radio" name="searchFilterRadioGroup" class="searchFilterRadio" value={{name}} {{#if selected}}checked{{/if}}>
				<img src={{{imageSource}}} class="searchImage" />
				<span class="filterDescription">
					{{{title}}<br><small class="muted">{{{description}}</small>
				</span>
			</label>
			{{/each}}'

	initialize: () =>
		$(document).on 'click', '.searchFilter .searchFilterRadio', @_handleRadioSelection
		

	render: () =>
		@$el.html @template 
			filters: @model.types.map (type) =>
				typeCopy = $.extend(true, {}, type);
				typeCopy.selected = typeCopy.name == @model.get('selectedType').name
				return typeCopy

		return @


	_handleRadioSelection: (event) =>
		@model.set 'selectedType', @model.getFilterTypeFromName event.target.value

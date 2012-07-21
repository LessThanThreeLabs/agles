exports.setup = (context) ->
	switch context.config.mode
		when 'development' then process.env.NODE_ENV = 'development'
		when 'production' then process.evn.NODE_ENV = 'production'
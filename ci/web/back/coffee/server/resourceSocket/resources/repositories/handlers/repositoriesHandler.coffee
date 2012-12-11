assert = require 'assert'

Handler = require '../../handler'


module.exports = class RepositoriesHandler extends Handler

	_fromPermissionString: (permissions) =>
		switch permissions
			when "r" then 1
			when "r/w" then 3
			when "r/w/a" then 7
			else 0

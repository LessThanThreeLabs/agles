ssert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new OrganizationsCreateHandler modelRpcConnection


class OrganizationsCreateHandler extends Handler
	default: (socket, data, callback) =>
		
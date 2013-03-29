assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new SystemSettingEventHandler sockets


class SystemSettingEventHandler extends EventHandler
	ROOM_PREFIX: 'systemSetting-'
	EVENT_PREFIX: 'systemSetting-'
	EVENT_NAMES: []


	processEvent: (data) =>
		roomName = @_getRoomName data.id, data.type
		eventName = @_getCompleteEventName data.id, data.type

		throw new Error 'Unexpected event type: ' + data.type
				
extend = require "extend"

class CachedData
  constructor: (@robot, @key) ->
    @robot.brain.on 'loaded', =>
      @robot.brain.data[@key] = @raw_data()

  raw_data: ->
    @robot.brain.data[@key] || {}

  extend: (objects...) ->
    data = @raw_data()
    extend true, data, objects...
    @set data

  get: (paths...) ->
    data = @raw_data()
    for path in paths
      return null if not data[path]?
      data = data[path]
    data

  set: (value, paths...) ->
    data = parent_data = @raw_data()
    last_path = paths.splice(-1,1)[0]
    for path in paths
      parent_data[path] = {} if not parent_data[path]?
      parent_data = parent_data[path]
    if last_path?
      parent_data[last_path] = value
    else
      data = value
    @robot.brain.data[@key] = data

  remove: (paths...) ->
    data = parent_data = @raw_data()
    last_path = paths.splice(-1,1)[0]
    for path in paths
      return if not parent_data[path]?
      parent_data = parent_data[path]
    if last_path?
      delete parent_data[last_path]
    else
      data = {}
    @robot.brain.data[@key] = data

  clean: ->
    @robot.brain.data[@key] = {}

class CachedDataWraper
  constructor: (robot, key) ->
    @data = new CachedData robot, key
    robot.catchAll (msg) =>
      state_data = @get msg
      state = state_data?.state || "default"
      robot.emit "#{key}_#{state}", msg, state_data

  extend: (msg, objects...) ->
    @data.extend @get_path(msg), objects...

  get: (msg, objects...) ->
    @data.get @get_path(msg), objects...

  set: (msg, data, objects...) ->
    @data.set data, @get_path(msg), objects...

  remove: (msg, objects...) ->
    @data.remove @get_path(msg), objects...

  get_path: (msg) -> throw "get_path is not implemented"

class RoomState extends CachedDataWraper
  constructor: (robot, key) ->
    super robot, "room_states_#{key}"

  get_path: (msg) -> msg.message?.room || msg

class UserState extends CachedDataWraper
  constructor: (robot, key) ->
    super robot, "user_states_#{key}"

  get_path: (msg) -> msg.message?.user?.id || msg


module.exports = exports = {
  CachedData
  RoomState
  UserState
}

path   = require "path"
should = require "should"

{CachedData, RoomState, UserState} = require "../src/state"
{Robot, TextMessage} = require "hubot"

describe "State", ->
  say = (string) =>
    @adapter.receive new TextMessage @user, string

  beforeEach (done) =>
    @http = get: {}, post: {}
    @robot = new Robot null, "mock-adapter", false, "hubot"
    @robot.adapter.on "connected", =>
      @user = @robot.brain.userForId "1", name: "username", room: "roomid"
      @adapter = @robot.adapter
      done()
    @robot.run()

  afterEach =>
    @robot.shutdown()

  context "Cached data", =>
    beforeEach =>
      @data = new CachedData @robot, "test"

    afterEach =>
      @data.clean()
      delete @data

    it "get raw_data", =>
      @robot.brain.data.test = "abc"
      @data.raw_data().should.equal "abc"

    it "return empty hash if data is not provided", =>
      @data.raw_data().should.be.empty()

    it "can extend object", =>
      @robot.brain.data.test = test: "value"
      @data.extend test2: "value2", test3: child: "value"
      @robot.brain.data.test.should.deepEqual test: "value", test2: "value2", test3: child: "value"

    it "overwrite value when extend", =>
      @robot.brain.data.test = test: child1: "value1", child2: "value2"
      @data.extend test: child1: "new value", child3: "value3"
      @robot.brain.data.test.should.deepEqual test: child1: "new value", child2: "value2", child3: "value3"

    it "get value", =>
      @robot.brain.data.test = "abc"
      @data.get().should.equal "abc"

    it "get value from path", =>
      @robot.brain.data.test = test: "abc"
      @data.get("test").should.equal "abc"

    it "return null when value is not existed", =>
      @data.get().should.be.empty()
      should(@data.get("test")).null()
      @robot.brain.data.test = "abc"
      should(@data.get("test", "test2", "test3")).null()

    it "can set value", =>
      @data.set "value"
      @robot.brain.data.test.should.equal "value"

    it "can set value from path", =>
      @data.set "value", "path1", "path2"
      @robot.brain.data.test.should.deepEqual path1: path2: "value"

    it "not overwrite value if not need", =>
      @robot.brain.data.test = test: child1: "abc", child2: "xyz"
      @data.set "value", "test", "child3"
      @robot.brain.data.test.should.deepEqual test: child1: "abc", child2: "xyz", child3: "value"

    it "remove data", =>
      @robot.brain.data.test = test: "value"
      @data.remove()
      @robot.brain.data.test.should.be.empty()
      @robot.brain.data.test = test: child1: "value1", child2: "value2"
      @data.remove "test", "child1"
      @robot.brain.data.test.should.deepEqual test: child2: "value2"

    it "not throw if delete not existed data", =>
      @robot.brain.data.test = test: "value"
      @data.remove "test", "test2"
      @robot.brain.data.test.should.deepEqual test: "value"

    it "clean data", =>
      @robot.brain.data.test = test: "value"
      @data.clean()
      @robot.brain.data.test.should.be.empty()

    it "set data without set method", =>
      @robot.brain.data.test = test: child1: "abc", child2: "xyz"
      data = @data.get "test"
      data.child1 = "foo"
      @robot.brain.data.test.should.deepEqual test: child1: "foo", child2: "xyz"

  context "RoomState", =>
    beforeEach =>
      @state = new RoomState @robot, "test"

    afterEach =>
      delete @state

    it "trigger default message event", (done) =>
      @robot.on "room_states_test_default", -> done()
      say "abc"

    it "trigger correct message event", (done) =>
      @robot.brain.data.room_states_test = roomid: state: "foo"
      @robot.on "room_states_test_default", -> throw "should not called"
      @robot.on "room_states_test_foo", -> done()
      say "abc"

  context "UserState", =>
    beforeEach =>
      @state = new UserState @robot, "test"

    afterEach =>
      delete @state

    it "trigger default message event", (done) =>
      @robot.on "user_states_test_default", -> done()
      say "abc"

    it "trigger correct message event", (done) =>
      @robot.brain.data.user_states_test = "1": state: "foo"
      @robot.on "user_states_test_default", -> throw "should not called"
      @robot.on "user_states_test_foo", -> done()
      say "abc"

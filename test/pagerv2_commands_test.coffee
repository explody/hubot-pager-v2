require('es6-promise').polyfill()

Helper = require 'hubot-test-helper'
helper = new Helper('../scripts/pagerv2_commands.coffee')
Hubot = require '../node_modules/hubot'

path   = require 'path'
nock   = require 'nock'
sinon  = require 'sinon'
expect = require('chai').use(require('sinon-chai')).expect

room = null

describe 'pagerv2_commands', ->

  hubotEmit = (e, data, tempo = 40) ->
    beforeEach (done) ->
      room.robot.emit e, data
      setTimeout (done), tempo
 
  hubotHear = (message, userName = 'momo', tempo = 40) ->
    beforeEach (done) ->
      room.user.say userName, message
      setTimeout (done), tempo

  hubot = (message, userName = 'momo') ->
    hubotHear "@hubot #{message}", userName

  hubotResponse = (i = 1) ->
    room.messages[i]?[1]

  hubotResponseCount = ->
    room.messages?.length - 1

  say = (command, cb) ->
    context "\"#{command}\"", ->
      hubot command
      cb()

  only = (command, cb) ->
    context.only "\"#{command}\"", ->
      hubot command
      cb()

  beforeEach ->
    do nock.enableNetConnect

    process.env.PAGERV2_API_KEY = 'xxx'
    room = helper.createRoom { httpd: false }
    room.robot.brain.userForId 'user', {
      name: 'user'
    }
    room.robot.brain.userForId 'user_with_email', {
      name: 'user_with_email',
      email_address: 'user@example.com'
    }

    room.receive = (userName, message) ->
      new Promise (resolve) =>
        @messages.push [userName, message]
        user = { name: userName, id: userName }
        @robot.receive(new Hubot.TextMessage(user, message), resolve)

  afterEach ->
    delete process.env.PAGERV2_API_KEY

  # ------------------------------------------------------------------------------------------------
  say 'pd version', ->
    it 'replies version number', ->
      expect(hubotResponse()).to.match /hubot-pager-v2 is version [0-9]+\.[0-9]+\.[0-9]+/

  # ------------------------------------------------------------------------------------------------
  context 'with a first time user,', ->
    say 'pd me', ->
      it 'asks to declare email', ->
        expect(hubotResponse())
          .to.eql "Sorry, I can't figure out your email address :( " +
                  'Can you tell me with `.pd me as <email>`?'

  context 'with a user that has unknown email,', ->
    beforeEach ->
      room.robot.brain.data.pagerv2 = { users: { } }
      @response = require('./fixtures/users_list-nomatch.json')
      nock('https://api.pagerduty.com')
        .get('/users')
        .reply(200, @response)

    say 'pd me', ->
      it 'asks to declare email', ->
        expect(hubotResponse())
          .to.eql "Sorry, I can't figure out your email address :( " +
                  'Can you tell me with `.pd me as <email>`?'

  context 'with a user that has a known email,', ->
    beforeEach ->
      room.robot.brain.data.pagerv2 = {
        users: {
          momo: {
            id: 'momo',
            name: 'momo',
            email: 'momo@example.com'
          }
        }
      }
      @response = require('./fixtures/users_list-match.json')
      nock('https://api.pagerduty.com')
        .get('/users')
        .reply(200, @response)

    say 'pd me', ->
      it 'asks to declare email', ->
        expect(hubotResponse())
          .to.eql "Sorry, I can't figure out your email address :( " +
                  'Can you tell me with `.pd me as <email>`?'

  # ------------------------------------------------------------------------------------------------
  # context 'user unknown', ->
  #   beforeEach ->
  #     @response = require('./fixtures/users_list-nomatch.json')
  #     nock('https://api.pagerduty.com')
  #       .get('/users')
  #       .reply(200, @response)

  #   say 'pd me as xxx@example.com', ->
  #     it 'says couac', ->
  #       expect(hubotResponse()).to.eql 'couac'

FileSystem = require("fs")

module.exports = class Lex

  constructor: (@file) ->
    @init()

  init: () ->
    @regex = /(\(|\)|\[|\]|,|->|=|\+|\-|\w+)/g
    @content = null
    @markedTokens = []

  getToken: (marked = true) ->
    if @content is null
      @content = FileSystem.readFileSync(@file)

    if marked and @markedTokens.length isnt 0
      return @markedTokens.shift() # get marked token

    token = @regex.exec(@content)
    return null if token is null

    token = {
      value: token[0]
      type: @getTokenType(token[0])
      line: @getLineFromIndex(token.index, @content)
    }

    return token

  markToken: (marked = false) ->
    token = @getToken(marked)
    @markedTokens.push(token)

    return token

  getTokenType: (token) ->
    if /\d+/.test(token) then return "number"
    if /\(|\)|\[|\]/.test(token) then return "bracket"
    if /,|->|=|\+|\-/.test(token) then return "operator"
    if /^(void|int)$/.test(token) then return "type"

    return "variable"

  getLineFromIndex: (index, input) ->
    regex = /\n/g
    line = 1

    loop
      match = regex.exec(input)
      break if not match? or match.index > index

      line++

    return line
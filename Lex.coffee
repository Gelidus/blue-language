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
      indent: 0
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
    if /^(return)$/.test(token) then return "keyword"

    return "variable"

  ###
    @variable content [String] is input content
  ###
  getLineFromIndex: (index) ->
    @lineMatcher = @lineMatcher || /\n/g
    @lastLine = @lastLine || 1

    if @eof isnt true
      @lastMatch = @lastMatch || @lineMatcher.exec(@content)

    if @eof or index < @lastMatch.index
      return @lastLine
    else
      match = @lineMatcher.exec(@content)
      if not @eof and match is null
        @eof = true
      else
        @lastMatch = match

      @lastLine++
      @getLineFromIndex(index) # recursive call to check forward lines

    return @lastLine
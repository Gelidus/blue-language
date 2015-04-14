FileSystem = require("fs")

module.exports = class Lex

  constructor: (@file) ->
    @init()

  init: () ->
    @regex = /(\(|\)|\[|\]|\".*\"|\@|,|:|->|=|\+|\-|\/|\*|\w+)/g
    @content = null
    @markedTokens = []
    @indentation = 0
    @tokenEof = false

    @lastMatch = { index: 1 }

  getToken: (marked = true) ->
    if @content is null
      @content = FileSystem.readFileSync(@file)

    if @tokenEof and not (marked and @markedTokens.length isnt 0)
      return null

    if marked and @markedTokens.length isnt 0
      return @markedTokens.shift() # get marked token

    token = @regex.exec(@content)
    if token is null
      @tokenEof = true
      return null

    token = {
      value: token[0]
      type: @getTokenType(token[0])
      line: {
        number: @getLineFromIndex(token.index, @content)
        indent: @indentation
      }
    }
    
    return token

  markToken: (marked = false) ->
    token = @getToken(marked)
    if marked and token isnt null
      @markedTokens.unshift(token)
    else if token isnt null
      @markedTokens.push(token)

    return token

  getTokenType: (token) ->
    if /\d+/.test(token) then return "number"
    if /^(\".*\")$/.test(token) then return "string"
    if /\(|\)|\[|\]/.test(token) then return "bracket"
    if /->|=|\+|\-|\/|\*|\@/.test(token) then return "operator"
    if /^(void|int|float|string)$/.test(token) then return "type"
    if /^(return|import)$/.test(token) then return "keyword"
    if /,|:/.test(token) then return "misc"

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

      # indentation calculation
      matchIndentIndex = if not match? then @content.length - 1 else @lastMatch.index - 1
      indent = 0
      loop
        break if matchIndentIndex < 0 # break on end
        if String.fromCharCode(@content[matchIndentIndex]) is "\n" # find nearest newline
          for i in [matchIndentIndex+1..@lastMatch.index] # match spaces from newline
            if String.fromCharCode(@content[i]) isnt " "
              matchIndentIndex = 0 # stop calculation
              break;

            indent++

        matchIndentIndex--

      @indentation = indent

      # line calculation
      @lastLine++
      @getLineFromIndex(index) # recursive call to check forward lines

    return @lastLine
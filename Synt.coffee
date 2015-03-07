Lex = require("./Lex")

module.exports = class Synt

  constructor: (file) ->
    @lex = new Lex(file)

  generateTree: () ->
    root = [] # generate tree root

    @parseFunctions(root) # parse functions

    return root

  parseFunctions: (root) ->

    loop
      returnType = @lex.getToken()
      break if returnType is null

      functionName = @lex.getToken()

      func = {
        nodeType: "function"
        name: functionName.value
        returnType: returnType.value
        indent: returnType.line.indent
      }

      func.parameters = @parseFunctionParameters(func)

      # -> operator
      arrow = @lex.getToken()

      # parse whole body
      func.body = @parseBody(func.indent)

      # register function into body
      root.push(func)

  parseFunctionParameters: (func) ->
    leftBracket = @lex.getToken()

    parameters = []
    loop
      type = @lex.markToken()
      break if type.value is ")" # break on right bracket
      @lex.getToken() # remove type token from front

      name = @lex.getToken()

      # create parameter object
      parameters.push({
        nodeType: "funcparam"
        type: type.value
        name: name.value
      })

      comma = @lex.markToken()
      break if comma.value is ")"
      @lex.getToken() # remote comma from front

    rightBracket = @lex.getToken()

    return parameters

  parseBody: (baseIndent) ->
    body = []

    loop
      any = @lex.markToken(true)
      break if any is null or not any.line.indent > baseIndent

      if any.type is "type"
        body.push(@parseDeclarationStatement())
      else if any.type is "variable" and @lex.markToken()? and @lex.markToken().value is "="
        body.push(@parseAssignStatement())
      else if any.type is "keyword" and any.value is "return"
        body.push(@parseReturnStatemnt())
      else
        body.push(@parseExpressionStatement())

    return body

  ###  Statements  ###

  ###
    (variable) = (expression)
  ###
  parseAssignStatement: () ->

  ###
    (type) (variable) [= (expression)]
  ###
  parseDeclarationStatement: () ->
    type = @lex.getToken()
    name = @lex.getToken()

    vardecl = {
      nodeType: "vardecl"
      type: type.value
      name: name.value
      expression: []
    }

    assign = @lex.markToken()
    if assign.type is "operator" and assign.value is "="
      @lex.getToken() # retrieve marked token
      vardecl.expression = @parseExpressionStatement()

    return vardecl

  ###
    (expression)
  ###
  parseExpressionStatement: () ->
    expression = {
      nodeType: "expression"
      body: []
    }
    expressionLine = null

    state = "variable"
    loop
      token = @lex.markToken(true)

      break if token is null or (expressionLine? and token.line.number isnt expressionLine)

      if state is "variable" and (token.type not in ["variable", "number", "string"])
        break

      if state is "operator" and (token.type not in ["operator", "bracket", "misc"])
        break;

      expressionLine = expressionLine || token.line.number
      token = @lex.getToken() # retrieve from marked tokens

      expression.body.push({
        nodeType: "exprnode"
        type: token.type
        value: token.value
      })

      state = if state is "variable" then "operator" else "variable"

    return expression

  ###
    return (expression)
  ###
  parseReturnStatemnt: () ->
    ret = @lex.getToken()

    expr = @parseExpressionStatement()

    return {
      nodeType: "return"
      expression: expr
    }

  ###              ###
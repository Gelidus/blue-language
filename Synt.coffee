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
      functionName = @lex.getToken()

      func = {
        nodeType: "function"
        name: functionName.value
        returnType: returnType.value
      }

      func.parameters = @parseFunctionParameters(func)

      # -> operator
      arrow = @lex.getToken()

      # parse whole body
      func.body = @parseBody(func.body)

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

  parseBody: () ->
    body = []

    loop
      any = @lex.markToken(true)
      break if any is null

      if any.type is "type" # variable declaration cause it's type
        body.push(@parseVariableDeclaration())
      else if any.type is "variable" and @lex.markToken().value is "("
        body.push(@parseFunctionCall())
      else if any.type is "keyword" and any.value is "return" # parse return
        body.push(@parseReturn())
      else
        console.log("Error on token: ")
        console.dir(any)
        break

    return body

  parseVariableDeclaration: () ->
    type = @lex.getToken()
    name = @lex.getToken()
    assign = @lex.getToken()
    banner = @parseExpression()

    variable = {
      nodeType: "vardecl"
      type: type.value
      name: name.value
      expression: banner
    }

    return variable

  parseFunctionCall: () ->
    name = @lex.getToken()
    leftBracket = @lex.getToken()
    args = @parseFunctionArguments()
    rightBracket = @lex.getToken()

    return {
      nodeType: "call"
      name: name.value
      args: args
    }

  parseFunctionArguments: () ->
    args = []

    loop
      expression = @parseExpression()
      if expression.length isnt 0
        args.push(expression)
      # comma
      separator = @lex.markToken(true)

      break if separator.value is ")"

    return args

  parseExpression: () ->
    expression = []

    state = "variable"
    loop
      token = @lex.markToken()

      if state is "variable" and (token.type isnt "variable" and token.type isnt "number")
        break

      if state is "operator" and (token.type isnt "operator")
        break;

      token = @lex.getToken() # retrieve the token from lex

      expression.push({
        nodeType: "exprnode"
        type: token.type
        value: token.value
      })

      state = if state is "variable" then "operator" else "variable"

    return expression

  parseReturn: () ->
    ret = @lex.getToken()

    expr = @parseExpression()

    return {
      nodeType: "return"
      expression: expr
    }
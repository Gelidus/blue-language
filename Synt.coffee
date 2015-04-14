Lex = require("./Lex")

module.exports = class Synt

  constructor: (file) ->
    @lex = new Lex(file)
    @syntaxData = { properties: [] }

  generateTree: () ->
    tree = {
      imports: []
      entities: []
    }

    loop
      # parse next entity
      entity = @parseEntity()
      break if not entity?

      # assign properties that were assembled before
      if entity.nodeType is "properties"
        @syntaxData.properties = entity.values
        continue
      else
        entity.properties = @syntaxData.properties
        @syntaxData.properties = []

      switch entity.nodeType
        when "function" then tree.entities.push(entity)
        when "import" then tree.imports.push(entity)

    return tree

  parseEntity: () ->
    first = @lex.markToken(true)

    return null if not first?

    if first.type is "keyword" and first.value is "import" # import
      return @parseImportStatement()
    else if first.type is "type" # function
      return @parseFunctionStatement()
    else if first.type is "operator" and first.value is "@" # property
      return @parsePropertyStatements()
    else
      throw new Error("Unexpected token #{first.value} on #{first.line.number}:#{first.line.indent}")

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
    import (variable)[:]
  ###
  parseImportStatement: () ->
    include = @lex.getToken() # import token
    name = @lex.getToken()

    include = {
      nodeType: "import"
      name: name.value
      option: "packed"
      body: { }
    }

    option = @lex.markToken(true)
    if option.type is "misc" and option.value is ":"
      option = @lex.getToken()
      include.option = "unpacked" # import all to current namespace "std:print"

    importAnalyser = new Synt("#{__dirname}/libs/cpp/#{include.name}.blue")
    importTree = importAnalyser.generateTree()

    return include

  ###
    @(variable) [([option[=value]], ...)]
  ###
  parsePropertyStatements: () ->
    properties = {
      nodeType: "properties"
      values: []
    }
    
    loop
      at = @lex.markToken(true)
      break if at.value isnt "@"
      @lex.getToken() # get @

      name = @lex.getToken()

      property = {
        nodeType: "property"
        name: name.value
        options: { }
      }

      properties.values.push(property)

      bracket = @lex.markToken(true)
      continue if bracket.type is "operator" and bracket.value is "@" # next property
      break if bracket.type isnt "bracket" and bracket.value isnt "(" # continue with scan

      bracket = @lex.getToken() # get actual bracket

      loop # inner loop for properties
        propertyToken = @lex.markToken(true)
        break if propertyToken.value is ")" # break on right bracket

        if propertyToken.value is ","
          propertyToken = @lex.getToken() # retrieve

        [propertyName, propertyExpression] = @parsePropertyStatement()
        property.options[propertyName] = propertyExpression

      rightBracket = @lex.getToken()

    console.log "Block"
    for property in properties.values
      console.dir property

    return properties

  ###
    (variable)[ = (expression)]
  ###
  parsePropertyStatement: () ->
    propertyName = @lex.getToken()
    assign = @lex.markToken(true)

    if assign.value isnt "="
      return [propertyName.value, true]

    assign = @lex.getToken()
    propertyExpression = @parseExpressionStatement()

    return [propertyName.value, propertyExpression]

  ###
    (type) (variable) ([variable, ...]) ->
  ###
  parseFunctionStatement: () ->
    returnType = @lex.getToken()

    return if returnType is null

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

    return func

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
    @parseExpressionByBasic()
    ###expression = {
      nodeType: "expression"
      body: []
    }
    expressionLine = null

    state = "variable"
    numberOfBrackets = 0
    loop
      token = @lex.markToken(true)

      break if token is null or (expressionLine? and token.line.number isnt expressionLine)

      if state is "variable" and (token.type not in ["variable", "number", "string"])
        break

      if state is "operator" and (token.type not in ["operator", "bracket", "misc"]) and token.value isnt ","
        break;

      expressionLine = expressionLine || token.line.number
      token = @lex.getToken() # retrieve from marked tokens

      expression.body.push({
        nodeType: "exprnode"
        type: token.type
        value: token.value
      })

      state = if state is "variable" then "operator" else "variable"

    return expression###

  # @bugged
  parseExpressionByShuntingYard: () ->
    outputQueue = []
    operatorStack = []

    expression = {
      nodeType: "expression"
      body: []
    }

    exit = false

    pushToken = (token) -> expression.body.push({ nodeType: "exprnode", type: token.type, value: token.value })

    loop
      break if exit #exit from algorithm

      token = @lex.markToken(true)
      break if not token? or (expression.body.length > 1 and token.type is expression.body[expression.body.length-1].type)

      if token.type is "number" or token.type is "variable"
        outputQueue.push(token)
      else if token.type is "operator"
        operatorStack.push(token)
      else if token.type is "bracket" and token.value is "("
        operatorStack.push(token)
      else if token.type is "bracket" and token.value is ")"
        loop
          stackTop = operatorStack.pop()
          break if stackTop.type is "bracket" and token.value is "("
          # mismatch on parenthesis if not found
          outputQueue.push(stackTop)

          if operatorStack.length is 0
            exit = true
            break
      else
        exit = true # unknown token
        break

      if not exit # found token that does not belong
        pushToken(token)
        @lex.getToken() # get token from que

    return expression

  parseExpressionByBasic: () ->
    expression = {
      nodeType: "expression"
      body: []
    }

    bracketsCount = 0 # count of brackets

    pushToken = (token) -> expression.body.push({ nodeType: "exprnode", type: token.type, value: token.value })

    loop
      token = @lex.markToken(true)
      [..., lastToken] = expression.body
      break if lastToken? and token? and (token.type is lastToken.type or (token.type in ["number", "string", "variable"] and lastToken.type in ["number", "string", "variable"]))# same types

      break if not token? # no more tokens
      break if token.type in ["keyword", "misc", "type"] or token.value in [",", "@"] # unavaliable operators and type
      break if token.type is "bracket" and token.value is ")" and bracketsCount is 0

      # use bracket counter to validate brackets
      bracketsCount-- if token.type is "bracket" and token.value is ")"
      bracketsCount++ if token.type is "bracket" and token.value is "("

      pushToken(@lex.getToken()) # retrieve token

    return expression

  getOperatorPrecendence: (token) ->
    throw new Error("Token is not operator") if token.type isnt "operator"

    return 2 if token.value in ["+", "-"]
    return 3 if token.value in ["*", "/"]

    throw new Error("Unrecognized token specified #{token.type}:#{token.value}")

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
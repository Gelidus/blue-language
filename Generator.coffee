Synt = require("./Synt")

module.exports = class Generator

  constructor: () ->

  generate: (tree) ->

    fileContent = ""

    # generate includes for language
    fileContent += @_generateIncludes() + "\n\n"

    for func in tree.entities
      fileContent += @generateFunction(func)
      fileContent += "\n\n"

    return fileContent
    
  _generateIncludes: () ->
    return "#include <iostream>\n#include <stdio.h>"

  ###
    func = {
      nodeType, name, returnType, parameters[], body[]
    }
  ###
  generateFunction: (func) ->
    functionBuilder = ""
    indentation = 2

    functionParameters = ""
    functionParameters += "#{param.type} #{param.name}, " for param in func.parameters
    functionParameters = functionParameters.trim().slice(0, -1) # get rid of last comma

    # function header
    functionBuilder += "#{func.returnType} #{func.name} (#{functionParameters}) {\n"

    # function body, this is array of lines
    body = @generateBody(func.body)
    for line in body
      functionBuilder += " ".repeat(indentation) + "#{line}\n"

    # trim newlines
    functionBuilder = functionBuilder.trim("\n")

    # function tail
    functionBuilder += "\n}"

    return functionBuilder

  ###
    @param body [Object] body to generate
    @returns Array of lines
  ###
  generateBody: (body) ->
    lines = []

    ###
      node = {
        nodeType: vardecl [ type, name, expression ], call [ name, args ]
      } 
    ###
    for node in body
      lines.push(@generateVarDeclaration(node)) if node.nodeType is "vardecl"
      lines.push(@generateFunctionCall(node)) if node.nodeType is "call"
      lines.push(@generateReturn(node)) if node.nodeType is "return"
      lines.push(@generateExpression(node) + ";") if node.nodeType is "expression"

    return lines


  ###
    vardecl = {
      type, name, expression = { nodeType="exprnode", type, value }
    }
  ###
  generateVarDeclaration: (vardecl) ->
    vardeclBuilder = ""

    vardeclBuilder += "#{vardecl.type} #{vardecl.name} = "

    vardeclBuilder += @generateExpression(vardecl.expression)

    vardeclBuilder = vardeclBuilder.trim()
    vardeclBuilder += ";"

    return vardeclBuilder

  generateReturn: (ret) ->
    returnBuilder = ""

    returnBuilder += "return #{@generateExpression(ret.expression)};"

    return returnBuilder

  ###
    expr = []{
      nodeType="exprnode", type, value
    }
  ###
  generateExpression: (expr) ->
    expressionBuilder = ""

    for expression in expr.body
      # indentation methods
      if expression.type is "operator"
        expressionBuilder += " #{expression.value} "
      else if expression.type is "misc" # ,
        expressionBuilder += "#{expression.value} "
      else
        expressionBuilder += "#{expression.value}"

    expressionBuilder = expressionBuilder.trim()

    return expressionBuilder
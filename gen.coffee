require("./util") # utils

Synt = require("./Synt")
Generator = require("./Generator")

input = process.argv[2]
output = process.argv[3]

synt = new Synt(input)
###
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
synt.lex.getToken()
###
generator = new Generator()

generator.generate(synt.generateTree(), output)
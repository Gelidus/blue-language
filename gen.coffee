require("./util") # utils

Synt = require("./Synt")
Generator = require("./Generator")

input = process.argv[2]
output = process.argv[3]

synt = new Synt(input)
generator = new Generator()

generator.generate(synt.generateTree(), output)
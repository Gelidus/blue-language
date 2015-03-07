require("./util") # utils

Synt = require("./Synt")
Generator = require("./Generator")

synt = new Synt("./lang/main.blue")

generator = new Generator("./lang/main.bblue")
generator.generate(synt.generateTree(), "#{__dirname}/generated/main.cpp")
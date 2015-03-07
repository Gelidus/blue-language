Synt = require("./Synt")
Generator = require("./Generator")

synt = new Synt("./lang/main.b")

generator = new Generator("./lang/main.b")
generator.generate(synt.generateTree(), "#{__dirname}/generated/main.cpp")
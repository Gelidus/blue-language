require("./util") # utils

Synt = require("./Synt")
Generator = require("./Generator")

input = process.argv[2]
output = process.argv[3]

synt = new Synt(input)
generator = new Generator()

tree = synt.generateTree()
require("fs").writeFileSync("./tree.json", JSON.stringify(tree, null, 2), "utf-8")

generator.generate(tree, output)
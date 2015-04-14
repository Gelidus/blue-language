args = require('minimist')(process.argv.slice(2));

throw new Error("Input file not specified!") if not args["c"]?

require("./util") # utils
FileSystem = require("fs")

Synt = require("./Synt")
Generator = require("./Generator")

synt = new Synt(args["c"])
generator = new Generator()

tree = synt.generateTree()
require("fs").writeFileSync("./tree.json", JSON.stringify(tree, null, 2), "utf-8")

output = generator.generate(tree)

if args["o"]?
  FileSystem.writeFileSync(args["o"], output)
else
  console.log(output)
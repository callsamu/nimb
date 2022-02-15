import ../src/parser/html
import std/[streams, unittest]

proc readHtml(filename: string): string =
  var stream = streams.newFileStream("tests/" & filename & ".html")

  result = stream.readAll()
  stream.close()

suite "testSnippets":
  test "buildsSimpleTree":
    let 
      data = readHtml("simple")
      parser = html.NewParser()
      tree = parser.parse(data)
    check tree.element == "html"


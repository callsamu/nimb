import ../src/parser/html

let
  htmlSnippet = """
  <html>
    <head>
      <title>Hello World</title>
    </head>
    <body>
      <h1>Hello HTML Parser</h1>
      <img>
      <p>Smile, you are being parsed</p>
    </body>
  </html>
"""

var parser = NewParser()
printTree(parser.parse(htmlSnippet))

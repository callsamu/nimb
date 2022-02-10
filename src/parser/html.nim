import std/[sets, strutils, strtabs]

const
  SELF_CLOSING_TAGS = toHashSet([
    "meta", "img", "br", "link",
    "hr", "track", "area", "input",
    "param", "source", "wbr"
  ])

type
  State* = enum
    StartTag,
    InClosingTag,
    InOpeningTag,
    WithAttributes,
    InText
  NodeKind = enum
    Element,
    Text
  Node* = ref object
    parent: Node
    case kind: NodeKind
    of Text: 
      text: string
    of Element: 
      element: string
      children: seq[Node]
      attributes: StringTableObj
  HTMLParser* = ref object
    openTags: seq[Node]
    counter: int
    current*: State
    previous: State

proc NewParser*(): HTMLParser =
  result = HTMLParser(counter: -1, current: InText)

proc transit(parser: HTMLParser, new: State) {.inline.} =
  parser.previous = parser.current
  parser.current = new

#[
proc parseAttribute(attribute: string): (string, string) {.inline.} =
  discard

proc parseTagWithAttributes(text: string): (string, StringTableObj) =
  let
    split = text.splitWhitespace()
    (tag, attributes) = (split[0], split[0..^1])

  for a in attributes:
    
  discard
]#

proc addTag(parser: HTMLParser, tag: string) {.inline.} =
  let 
    counter = parser.counter
    parent = 
      if counter >= 0:
        parser.openTags[counter]
      else: nil

  var node = Node(
    parent: parent,
    kind: Element,
    element: tag
  )

  if tag in SELF_CLOSING_TAGS and parent != nil:
    parser.openTags[counter].children.add(node)
  else:
    echo node.element
    parser.openTags.add(node)
    parser.counter += 1

proc addText(parser: HTMLParser, text: string) {.inline.} =
  var node = Node(
    parent: parser.openTags[parser.counter], 
    kind: Text,
    text: text
  )
  parser.openTags[parser.counter].children.add(node)

proc popTag(parser: HTMLParser) {.inline.} =
  if parser.counter == 0: return 
  let tag = parser.openTags.pop()
  echo tag.element
  echo tag.parent.element
  tag.parent.children.add(tag)
  parser.counter -= 1

proc printTree*(node: Node, sep = "--") =
  case node.kind:
    of Text:
      echo sep,node.text
    of Element:
      echo sep,node.element
      for children in node.children:
        printTree(children, sep&"--")

proc parse*(parser: HTMLParser, html: string): Node =
  var buffer: string

  for i, c in html:
    echo (parser.current, buffer, parser.counter)
    case parser.current:
      of InText:
        if c == '<':
          parser.transit(StartTag)
          buffer = buffer.strip(chars = {' ', '\n'})
          if buffer != "":
            parser.addText(buffer)
          buffer = ""
        else:
          buffer.add(c)
      of StartTag:
        if c == '/':
          parser.transit(InClosingTag)
        else:
          parser.transit(InOpeningTag)
          buffer.add(c)
      of InOpeningTag:
        if c == ' ':
          parser.transit(WithAttributes)
        elif c == '>':
          parser.transit(InText)
          parser.addTag(buffer)
          buffer = ""
        else:
          buffer.add(c)
      of InClosingTag:
        if c == '>':
          parser.transit(InText)
          parser.popTag()
          buffer = ""
        else:
          buffer.add(c)
      of WithAttributes:
        if c == '>':
          
          parser.addTag(buffer)
          buffer = ""
        buffer.add(c)

  result = parser.openTags[0]

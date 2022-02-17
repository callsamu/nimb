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
    case kind*: NodeKind
    of Text: 
      text*: string
    of Element: 
      element*: string
      children*: seq[Node]
      attributes*: StringTableObj
  HTMLParser* = ref object
    openTags: seq[Node]
    counter: int
    current*: State
    previous: State

proc NewParser*(): HTMLParser =
  result = HTMLParser(counter: -1, current: InText)

proc NewNode(parent: Node, kind: NodeKind, name: string): Node =
  result = Node(parent: parent, kind: kind)

  if parent != nil: parent.children.add(result)

  if kind == Element: result.element = name
  elif kind == Text: result.text = name

proc transit(parser: HTMLParser, new: State) {.inline.} =
  parser.previous = parser.current
  parser.current = new

proc addTag(parser: HTMLParser, tag: string) {.inline.} =
  let 
    counter = parser.counter
    parent = 
      if counter >= 0:
        parser.openTags[counter]
      else: nil

  var node = NewNode(parent, Element, tag)

  if tag notin SELF_CLOSING_TAGS or parent == nil:
    echo node.element
    parser.openTags.add(node)
    parser.counter += 1

proc addText(parser: HTMLParser, text: string) {.inline.} =
  let parent = parser.openTags[parser.counter]
  discard NewNode(parent, Text, text)

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
        printTree(children, sep & sep)

proc parse*(parser: HTMLParser, html: string): Node =
  var buffer, attribute, value: string

  var i = 0
  while i < html.len:
    let c = html[i]
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
          parser.transit(InOpeningTag)
          continue

    i += 1
  result = parser.openTags[0]

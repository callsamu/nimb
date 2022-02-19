import std/[sets, strutils, strtabs, parseutils]

const
  SELF_CLOSING_TAGS = toHashSet([
    "meta", "img", "br", "link",
    "hr", "track", "area", "input",
    "param", "source", "wbr"
  ])
  IN_HEAD_TAGS = toHashSet([
    "base", "basefont", "bgsound", "noscript",
    "link", "meta", "title", "style", "script"
  ])

type
  State* = enum
    InText,
    StartTag,
    InDoctype,
    InClosingTag,
    InOpeningTag,
    WithAttributes,
    OnAttributeName,
    OnAttributeEnd,
    OnAttributeValue,
    OnAttributeValueBegin,
    OnQuotedAttributeValue
  NodeKind = enum
    Element,
    Text
  Node* = ref object
    parent*: Node
    case kind*: NodeKind
    of Text: 
      text*: string
    of Element: 
      element*: string
      children*: seq[Node]
      attributes*: StringTableRef
  Document* = object
    root*, head*, body*: Node
  HTMLParser* = ref object
    openTags: seq[Node]
    counter: int
    current*: State
    previous: State
    attributes: StringTableRef

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

proc lastOpenTag(parser: HTMLParser): Node {.inline.} =
    let counter = parser.counter
    result = if counter < 0: nil 
             else: parser.openTags[counter]

proc popTag(parser: HTMLParser) {.inline.} =
  if parser.counter == 0: return 
  let tag = parser.openTags.pop()
  parser.counter -= 1

proc openImplicitTag(parser: HTMLParser, tag: string) =
    let node = NewNode(parser.lastOpenTag, Element, tag)
    node.attributes = newStringTable()
    parser.openTags.add(node)
    parser.counter += 1

proc implicitTag(parser: HTMLParser, tag: string): bool {.inline.} =
  if parser.counter < 0 and tag != "html":
    parser.openImplicitTag("html")
    return
  elif parser.counter == 0:
    if tag != "head" and tag in IN_HEAD_TAGS:
      parser.openImplicitTag("head")
      return
    elif tag != "body" and tag notin IN_HEAD_TAGS:
      parser.openImplicitTag("body")
      return
  elif parser.counter == 1:
    if tag notin IN_HEAD_TAGS and 
      parser.openTags[1].element == "head":
      parser.popTag()
      return
  elif parser.lastOpenTag().element == "p" and tag == "p":
    parser.popTag()
    return

  result = true

proc addTag(parser: HTMLParser, tag: string, attributes: StringTableRef) {.inline.} =
  let tag = tag.strip()
  while not parser.implicitTag(tag): discard

  var node = NewNode(parser.lastOpenTag(), Element, tag)
  node.attributes = attributes

  if tag notin SELF_CLOSING_TAGS:
    parser.openTags.add(node)
    parser.counter += 1

proc addText(parser: HTMLParser, text: string) {.inline.} =
  while not parser.implicitTag(""): discard
  discard NewNode(parser.lastOpenTag(), Text, text)

proc printTree*(node: Node, sep = "--") =
  case node.kind:
    of Text:
      echo sep,node.text
    of Element:
      var attributes: string

      for (key, value) in pairs(node.attributes):
        attributes.add(key & "=" & value & ",")

      echo sep,node.element,": ",attributes
      for children in node.children:
        printTree(children, sep & "--")

proc finish(parser: HTMLParser): Document =
  while parser.counter > 0: parser.popTag()

  let 
    root = parser.openTags.pop()
    head = root.children[0]
    body = root.children[1]

  result = Document(root: root, head: head, body: body)

proc parse*(parser: HTMLParser, html: string): Document =
  var 
    buffer, attribute, value: string
    attributeTable: StringTableRef;

  var i = 0
  while i < html.len:
    let c = html[i]

    case parser.current:
      of InText:
        i += html.parseUntil(buffer, '<', i)
        parser.transit(StartTag)
        attributeTable = newStringTable()
        buffer = buffer.strip(chars = {' ', '\n'})
        if buffer != "":
          parser.addText(buffer)
        buffer = ""
      of StartTag:
        if c == '/':
          parser.transit(InClosingTag)
        elif c == '!':
          parser.transit(InDoctype)
        else:
          parser.transit(InOpeningTag)
          buffer.add(c)
      of InDoctype:
        i += html.skipUntil('>', start = i)
        parser.transit(InText)
      of InOpeningTag:
        if c == ' ':
          parser.transit(WithAttributes)
        elif c == '>':
          parser.transit(InText)
          parser.addTag(buffer, attributeTable)
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
        while html[i] == ' ': i += 1
        if html[i] == '>': parser.transit(InOpeningTag)
        else: parser.transit(OnAttributeName)
        continue
      of OnAttributeName:
        i += html.parseIdent(attribute, start = i)
        if html[i] != '=':
          value = "true"
          parser.transit(OnAttributeEnd)
          continue
        parser.transit(OnAttributeValueBegin)
      of OnAttributeValueBegin:
        if c == '"': 
          parser.transit(OnQuotedAttributeValue)
        else: 
          parser.transit(OnAttributeValue)
          continue
      of OnQuotedAttributeValue:
        i += html.parseUntil(value, '"', start = i)
        parser.transit(OnAttributeEnd)
      of OnAttributeValue:
        i += html.parseUntil(value, {' ', '>'}, start = i)
        parser.transit(OnAttributeEnd)
        continue
      of OnAttributeEnd:
        attributeTable[attribute] = value
        (attribute, value) = ("", "")
        parser.transit(WithAttributes)
        continue

    i += 1

  result = parser.finish()

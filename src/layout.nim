import strutils
import pixie as pix

var mainFont = readTypeface("fonts/FreeSans.ttf")

type
  Display* = tuple
    pos: Vec2
    span: Span
  Layout* = object
    display*: seq[Display]
    height*: float

proc newLayout*(text: string, w, h: float): Layout =
  let face = mainFont
    
  var 
    x, y: float = 0.0
    font = newFont(face)
    yd = font.defaultLineHeight() * 1.50

  font.size = 20.0
  font.paint = rgba(0, 0, 0, 255)

  let whitespace = font.computeBounds(" ").x

  for line in text.splitLines:
    for word in line.splitWhitespace:
      let 
        w = font.computeBounds(word).x
        span = newSpan(word, font)
      if w + x > w:
        y += yd
        x = 0
      result.display.add((
        vec2(x, y), 
        span
      ))
      x += w + whitespace
    y += yd
    x = 0
  y += yd

  result.height = 
    if y > h: h
    else: y





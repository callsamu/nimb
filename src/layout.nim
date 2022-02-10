import strutils
import pixie as pix

var mainFont = readTypeface("fonts/FreeSans.ttf")

type
  Display* = tuple
    pos: Vec2
    span: Span
  Layout* = seq[Display]

proc newLayout*(text: string, width: float): Layout =
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
      if w + x > width:
        y += yd
        x = 0
      result.add((vec2(x, y), span))
      x += w + whitespace
    y += yd
    x = 0


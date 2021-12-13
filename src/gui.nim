import nigui
import network
import os

const scrollFactor = 20

type 
  Display = tuple
    x, y: int
    c: char
  Layout = seq[Display]
  Browser = ref object
    window: Window
    control: Control
    layout: Layout
    page: string

var scroll: int

proc buildLayout(browser: Browser): Layout =
  var x, y = 0
  let (xD, yD) = (12, 20)

  for c in browser.page:
    if c == '\n' or x >= browser.window.width:
      y += yD
      x = 0
    result.add((x, y, c))
    x += xD

proc bindRenderer(browser: Browser) =
  browser.control.onDraw = proc (event: DrawEvent) =
    let canvas = event.control.canvas
    canvas.areaColor = rgb(255, 255, 255)
    canvas.textColor = rgb(0, 0, 0)
    canvas.fontSize = 20
    canvas.fontFamily = "monospace"
    canvas.fill()

    browser.layout = browser.buildLayout()

    for (x, y, c) in browser.layout:
      canvas.drawText($c, x, y - scroll * scrollFactor)

proc redraw(browser: Browser) =
  browser.layout = browser.buildLayout()
  browser.control.forceRedraw()

proc bindResize(browser: Browser) =
  browser.window.onResize = proc (event: ResizeEvent) =
    browser.redraw()

proc bindKeyEvent(browser: Browser) =
  browser.window.onKeyDown = proc (event: KeyboardEvent) =
    case event.key:
      of Key_Down:
          scroll += 1 
      of Key_Up:
        if scroll > 0:
          scroll -= 1
      else: discard

    browser.redraw()

proc NewBrowser(width, height: int): Browser =
  var win = newWindow("web bOwOser")
  win.width = width
  win.height = width

  var control = newControl()
  control.widthMode = WidthMode_Fill
  control.heightMode = HeightMode_Fill
  win.add(control)

  result = Browser(window: win, control: control)
  result.bindRenderer()
  result.bindKeyEvent()
  result.bindResize

proc load(browser: Browser, url: string) =
  browser.page = request(url)

proc init(parameter: string) =
  app.init()

  var browser = NewBrowser(800, 600)
  browser.load(parameter)

  browser.window.show()
  app.run()

init(commandLineParams()[0])

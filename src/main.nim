import sdl2
import pixie as pix
import strutils
from network import request


const
  rmask = uint32 0x000000ff
  gmask = uint32 0x0000ff00
  bmask = uint32 0x00ff0000
  amask = uint32 0xff000000

var mainFont = readTypeface("FreeSans.ttf")

type
  Browser = ref object
    window: WindowPtr
    renderer: RendererPtr
    screen: TexturePtr
    layout: Layout
    scroll: float32
  Display = tuple
    pos: Vec2
    span: Span
  Layout = seq[Display]

proc buildLayout(self: Browser, text: string): Layout =
  let 
    face = mainFont
    maxWidth = self
      .window.getSize().x.float
    
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
      if w + x > maxWidth:
        y += yd
        x = 0
      result.add((vec2(x, y), span))
      x += w + whitespace
    y += yd
    x = 0

proc newBrowser(title: string): Browser =
  let 
    window = createWindow(title, 0, 0, 800, 600, 0)
    render = window.createRenderer(-1, Renderer_Accelerated)

  render.setDrawColor(0, 0, 0, 0)
  result = Browser(window: window, renderer: render)

proc destroy(self: Browser) =
  destroyRenderer(self.renderer)
  destroy(self.window)

proc renderScreen(self: Browser) =
  var image = pix.newImage(800, 600)
  let 
    maxHeight = self.window.getSize().y
    scroll = vec2(0, self.scroll)

  image.fill(rgba(255, 255, 255, 255))

  for (pos, span) in self.layout:
    let sPos = pos + scroll
    if sPos.y < 0: continue
    elif sPos.y > maxHeight.float: break

    image.fillText(
      span.font, 
      span.text,
      translate(sPos)
    )

  var 
    data = image.data[0].addr
    surface: SurfacePtr

  surface = sdl2.createRGBSurfaceFrom(
    data, cint 800, cint 600, 
    cint 32, cint 4*800, rmask, 
    gmask, bmask, amask
  )
  
  self.screen = self.renderer
    .createTextureFromSurface(surface)

proc display(self: Browser) =
  self.renderer.clear()
  self.renderer.copy(self.screen, nil, nil)
  self.renderer.present()
    
proc main(url: string) =
  sdl2.init(INIT_EVERYTHING)

  var
    browser = newBrowser("brOwOser")
    evt: sdl2.Event
  
  browser.layout = browser.buildLayout(request(url))

  while true:
    while (sdl2.pollEvent(evt)):
      case evt.kind:
        of QuitEvent:
          browser.destroy()
          return
        of KeyDown:
          case evt.key.keysym.scancode:
            of SDL_SCANCODE_UP:
              browser.scroll += 4.0
            of SDL_SCANCODE_DOWN:
              browser.scroll -= 4.0
            else: discard
        else: discard
    browser.renderScreen()
    browser.display()


main("https://stallman.org/")

